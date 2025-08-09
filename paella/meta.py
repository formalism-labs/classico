
import inspect, functools

# def add_fn_args(base_fn, template_fn):
#     """
#     Return a new function that behaves like `base_fn` but also
#     advertises the parameters of `template_fn`.
#     """
#     sig_base = inspect.signature(base_fn)
#     sig_template = inspect.signature(template_fn)
# 
#     # Order: keep base parameters first, then template’s (excluding duplicates)
#     new_params = list(sig_base.parameters.values())
#     for name, param in sig_template.parameters.items():
#         if name not in sig_base.parameters:
#             # Make extras keyword-only so we don't shift positions
#             new_params.append(param.replace(kind=inspect.Parameter.KEYWORD_ONLY))
# 
#     new_sig = inspect.Signature(new_params)
# 
#     @functools.wraps(base_fn)
#     def wrapper(*args, **kwargs):
#         return base_fn(*args, **kwargs)
# 
#     wrapper.__signature__ = new_sig  # for help()/IDE
#     return wrapper

def extract_args(func):
    return list(inspect.signature(func).parameters.values())

# def with_args_from(args_func):
#     def decorator(func):
#         return add_fn_args(func, args_func)
#         
#     return decorator
