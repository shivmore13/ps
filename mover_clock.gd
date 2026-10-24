extends RefCounted
class_name MoverClock
## Small shared timing helper for objects affected by the time abilities.
## `frozen` halts motion, `time_scale` slows it, `reversed` runs it backwards.

var frozen := false
var time_scale := 1.0
var reversed := false


## Effective delta for one step. Returns 0 while frozen.
func step(delta: float) -> float:
	if frozen:
		return 0.0
	return delta * time_scale * (-1.0 if reversed else 1.0)
