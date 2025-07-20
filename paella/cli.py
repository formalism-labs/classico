
import textwrap
from typing import Optional
import typing_extensions
from typing_extensions import Annotated
import typer
import click
import rich
import inspect, functools
import json
from .meta import *

#----------------------------------------------------------------------------------------------

# This gets overridden by App constructor
def App_common_options(): pass

#----------------------------------------------------------------------------------------------

class TyperApp(typer.Typer):
    @staticmethod
    def callback(ctx: typer.Context):
        app = ctx.obj["typer"]
        app.init()

    def __init__(self, help=None, epilog=None):
        cb = add_fn_args(TyperApp.callback, App_common_options)
        if help is None:
            help = self.prolog()
        if epilog is None:
            epilog = self.epilog()
        app = super().__init__(help=help, epilog=epilog,
            rich_markup_mode="markdown",
            no_args_is_help=False, #True,
            add_completion=False,
            invoke_without_command=True,
            callback=cb,
            context_settings={
                "help_option_names": ["-h", "-?", "--help"],
                "max_content_width": 120})

    def init(self):
        pass
    
    def __app(self):
        return self

    def prolog(self):
        return ""

    def epilog(self):
        return ""
    
    def run(self):
        super().__call__(obj={"typer": self.__app()})
        
    def to_json(self):
        return click.get_current_context().params

#----------------------------------------------------------------------------------------------

def cli_app(cls):
    class _App(TyperApp):
        def __init__(self, *args, **kwargs):
            try:
                globals()['App_common_options'] = cls.common_options
            except:
                pass

            self._app = cls(*args, **kwargs)
            super().__init__(*args, **kwargs)

        def __app(self):
            return self

        def init(self):
            return self._app.init()

        def prolog(self):
            try:
                return textwrap.dedent(self._app.prolog())
            except:
                return ""
            
        def epilogtext(self):
            try:
                return textwrap.dedent(self._app.epilog())
            except:
                return ""
            
        def __getattr__(self, name):
            return getattr(self._app, name)

    return _App

#----------------------------------------------------------------------------------------------

def Option(*args, **kwargs):
    group = kwargs.pop("group", None)
    if group is not None:
        kwargs["rich_help_panel"] = group
    return typer.Option(*args, **kwargs)

Annotated = typing_extensions.Annotated
Argument = typer.Argument
