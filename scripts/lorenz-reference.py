"""Independent test fixtures: SciPy DOP853, rtol=atol=1e-13, initial (1,1,1).
Run using a Python environment containing NumPy/SciPy; neither is an app dependency.
"""
import json
import scipy
from scipy.integrate import solve_ivp

def derivative(t, p):
    x, y, z = p
    return [10 * (y-x), x*(28-z)-y, x*y-(8/3)*z]

result = solve_ivp(derivative, [0, 1], [1, 1, 1], method="DOP853",
                   t_eval=[0.1, 0.5, 1], rtol=1e-13, atol=1e-13)
assert result.success
print(json.dumps({"scipy": scipy.__version__, "time": result.t.tolist(),
                  "points": result.y.T.tolist()}, indent=2))
