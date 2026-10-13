// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: debugger.go
// Upstream attribution: Google Inc. (see NOTICE).
// Modifications: Adapted stepping and breakpoint contracts to synchronous MoonBit callbacks.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
pub(all) enum DebugStopReason {
  Step
  Breakpoint
  Exception
} derive(Eq, Debug)

///|
pub extend DebugStopReason with Eq::{equal, not_equal}

///|
pub extend DebugStopReason with @debug.Debug::{to_repr}

///|
/// Return a continuation from the stop callback. Finish runs until the current
/// expression returns, then requests a step at the next nonliteral expression.
pub(all) enum DebugCommand {
  Continue
  Step
  Finish
  Terminate
}

///|
pub(all) struct DebugStop {
  reason : DebugStopReason
  context : EvalContext
  outcome : EvalOutcome?
}

///|
/// Synchronous host-controlled debugger. A stop callback may wait for a UI or
/// terminal command before returning. The supplied evaluator retains its normal
/// parameters/import configuration and caches; its previous hook is restored.
pub struct Debugger {
  priv evaluator : Evaluator
  priv breakpoints : Map[String, SourceRange]
  priv mut stepping : Bool
  priv mut finishing : Int?
  priv mut terminated : Bool
  priv mut running : Bool
}

///|
pub fn Debugger::new(evaluator? : Evaluator = Evaluator::new()) -> Debugger {
  {
    evaluator,
    breakpoints: Map([]),
    stepping: false,
    finishing: None,
    terminated: false,
    running: false,
  }
}

///|
/// Independent ranges in lowered semantic traversal order. Nodes without a
/// source range are omitted; repeated ranges from compiler sugar are retained.
pub fn Debugger::breakpoint_locations(program : Program) -> Array[SourceRange] {
  let ranges = []
  let stack = [program.expression]
  while stack.pop() is Some(node) {
    if node.end is Some(end) {
      ranges.push({ begin: node.loc, end, })
    }
    let children = debugger_children(node)
    for i = children.length() - 1; i >= 0; i = i - 1 {
      stack.push(children[i])
    }
  }
  ranges
}

///|
pub fn Debugger::set_breakpoint(
  self : Debugger,
  program : Program,
  line : Int,
  column? : Int,
) -> String raise JsonnetError {
  let ranges = Debugger::breakpoint_locations(program)
  guard ranges.search_by(range => {
      range.begin.line == line &&
      column.map(c => c < 0 || range.begin.column == c).unwrap_or(true)
    })
    is Some(index) else {
    raise problem(
      Runtime,
      program.expression.loc,
      "breakpoint location invalid",
    )
  }
  let range = ranges[index]
  let identity = range.format()
  self.breakpoints[identity] = range
  identity
}

///|
pub fn Debugger::active_breakpoints(self : Debugger) -> Array[String] {
  let result = self.breakpoints.keys().collect()
  result.sort_by(compare_unicode)
  result
}

///|
pub fn Debugger::clear_breakpoints(self : Debugger, filename : String) -> Unit {
  let remove = self.breakpoints
    .keys()
    .filter(key => self.breakpoints[key].begin.file == filename)
    .collect()
  for key in remove {
    ignore(self.breakpoints.remove(key))
  }
}

///|
fn debugger_stoppable(ctx : EvalContext) -> Bool {
  if ctx.source_range() is None {
    return false
  }
  match ctx.expression.kind {
    Literal(_) | NumberLiteral(_) | StandardFunction(_) | StandardValue(_) =>
      false
    _ => true
  }
}

///|
fn Debugger::continue_from(
  self : Debugger,
  stop : DebugStop,
  callback : (DebugStop) -> DebugCommand raise,
) -> Unit raise {
  match callback(stop) {
    Continue => self.stepping = false
    Step => self.stepping = true
    Finish => {
      self.stepping = false
      self.finishing = Some(stop.context.serial)
    }
    Terminate => {
      self.terminated = true
      raise problem(Runtime, stop.context.location(), "debugger terminated")
    }
  }
}

///|
/// Evaluate text while servicing breakpoints, stepping and exception stops.
/// Live contexts/values expire when the callback returns. Metadata and copied
/// nodes can be retained. Reentrant runs/configuration changes are rejected.
pub fn Debugger::run(
  self : Debugger,
  program : Program,
  on_stop~ : (DebugStop) -> DebugCommand raise,
  start_with_step? : Bool = false,
) -> String raise JsonnetError {
  if self.running {
    raise problem(
      Runtime,
      program.expression.loc,
      "debugger is already executing",
    )
  }
  self.evaluator.idle()
  self.running = true
  self.stepping = start_with_step
  self.finishing = None
  self.terminated = false
  let mut entered_source = false
  let previous = self.evaluator.eval_hook
  defer {
    self.evaluator.eval_hook = previous
    self.running = false
  }
  self.evaluator.set_eval_hook(hook={
    before: ctx => {
      if ctx.location().file != "<std>" {
        entered_source = true
      }
      if entered_source && !self.terminated && debugger_stoppable(ctx) {
        if self.stepping && self.finishing is None {
          self.stepping = false
          self.continue_from(
            { reason: Step, context: ctx, outcome: None, },
            on_stop,
          )
        } else if ctx.source_range() is Some(range) &&
          self.breakpoints.contains(range.format()) {
          self.continue_from(
            { reason: Breakpoint, context: ctx, outcome: None, },
            on_stop,
          )
        }
      }
    },
    after: (ctx, outcome) => {
      if !self.terminated && outcome is Failure(_) {
        self.continue_from(
          { reason: Exception, context: ctx, outcome: Some(outcome), },
          on_stop,
        )
      }
      if self.finishing == Some(ctx.serial) {
        self.finishing = None
        self.stepping = true
      }
    },
  })
  self.evaluator.evaluate_text(program)
}
