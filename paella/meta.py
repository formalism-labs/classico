
import inspect, functools

def add_fn_args(base_fn, template_fn):
    """
    Return a new function that behaves like `base_fn` but also
    advertises the parameters of `template_fn`.
    """
    sig_base = inspect.signature(base_fn)
    sig_template = inspect.signature(template_fn)

    # Order: keep base parameters first, then template’s (excluding duplicates)
    new_params = list(sig_base.parameters.values())
    for name, param in sig_template.parameters.items():
        if name not in sig_base.parameters:
            # Make extras keyword-only so we don't shift positions
            new_params.append(param.replace(kind=inspect.Parameter.KEYWORD_ONLY))

    new_sig = inspect.Signature(new_params)

    @functools.wraps(base_fn)
    def wrapper(*args, **kwargs):
        # Split kwargs for each underlying function
        kw_base     = {k: v for k, v in kwargs.items() if k in sig_base.parameters}
        kw_template = {k: v for k, v in kwargs.items() if k in sig_template.parameters}
        # Call both functions (or ignore template if you only need its arg list)
        result = base_fn(*args, **kw_base)
        template_fn(**kw_template)  # optional side call
        return result

    wrapper.__signature__ = new_sig  # for help()/IDE
    return wrapper
