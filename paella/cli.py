
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

class TyperApp(typer.Typer):
    def __init__(self, help=None, epilog=None):
        if help is None:
            help = self.prolog()
        if epilog is None:
            epilog = self.epilog()
        app = super().__init__(help=help, epilog=epilog,
            rich_markup_mode="markdown",
            no_args_is_help=False, #True,
            add_completion=False,
            invoke_without_command=True,
            context_settings={
                "help_option_names": ["-h", "-?", "--help"],
                "max_content_width": 120})

#    def __app(self):
#        return self
#
#    def run(self):
#        super().__call__(obj={"typer": self.__app()})
        
    def prolog(self):
        return ""

    def epilog(self):
        return ""
    
    def to_json(self):
        return click.get_current_context().params

#----------------------------------------------------------------------------------------------

def cli_app(cls):
    class _App(TyperApp):
        App = cls

        def __init__(self, *args, **kwargs):
            self.app = cls(*args, **kwargs)
            super().__init__(*args, **kwargs)

        def __getattr__(self, name):
            return getattr(self.app, name)

        def __app(self):
            return self

        def command(self, *args, **kwargs):
            _super = super()
            is_main = kwargs.pop('main', False)
            if is_main:
                self._fix_help_text(kwargs)
            def decorator(func):
                return _super.command(*args, **kwargs)(func)
            return decorator

        def _fix_help_text(self, kwargs):
            if 'help' not in kwargs:
                kwargs['help'] = self.prolog()
            if 'epilog' not in kwargs:
                kwargs['epilog'] = self.epilog()

        def prolog(self):
            try:
                return textwrap.dedent(self.app.prolog())
            except:
                return ""

        def epilog(self):
            try:
                return textwrap.dedent(self.app.epilog())
            except:
                return ""

    return _App

#----------------------------------------------------------------------------------------------

def Option(*args, **kwargs):
    group = kwargs.pop("group", None)
    if group is not None:
        kwargs["rich_help_panel"] = group
    return typer.Option(*args, **kwargs)

#----------------------------------------------------------------------------------------------

Annotated = typing_extensions.Annotated
Argument = typer.Argument
