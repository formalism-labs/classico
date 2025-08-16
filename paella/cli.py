
import sys
import textwrap
# from typing import Optional
import typing_extensions
from typing_extensions import Annotated
import typer
import click
import rich
import inspect, functools
import json
from .meta import *

#----------------------------------------------------------------------------------------------

class Command(typer.core.TyperCommand):
    def __init__(self, *args, **kwargs):
        ctx_settings = kwargs.get("context_settings", None)
        if ctx_settings is not None:
            typer_app = ctx_settings.pop("typer_app", None)
            self.typer_app = typer_app
        super().__init__(*args, **kwargs)

#    def __getattr__(self, name):
#        return getattr(super(), name)

    def collect_usage_pieces(self, ctx):
        pieces = super().collect_usage_pieces(ctx)
        extra_args = self.typer_app.extra_args_desc()
        if extra_args is not None:
            pieces.append(f"[-- {extra_args}]")
        return pieces
        
class CommandInfo:
    def __init__(self, typer_app, cmd_info):
        self.cls = Command
        self.typer_app = typer_app
        self.cmd_info = cmd_info

    def __getattr__(self, name):
        return getattr(self.cmd_info, name)

    def __setattr__(self, name, value):
        super().__setattr__(name, value)
        if name == "context_settings":
            self.context_settings["typer_app"] = self.typer_app

class TyperApp(typer.Typer):
    def __init__(self, help=None, epilog=None):
        if help is None:
            help = self.prolog()
        if epilog is None:
            epilog = self.epilog()
        self.extra_args = []

        super().__init__(help=help, epilog=epilog,
            rich_markup_mode="markdown",
            no_args_is_help=False, #True,
            add_completion=False,
            invoke_without_command=True,
            context_settings={
                "help_option_names": ["-h", "-?", "--help"],
                "max_content_width": 120})

    def extract_extra_args(self):
        if "--" not in sys.argv[1:]:
            return
        idx = sys.argv.index("--")
        self.extra_args = sys.argv[idx+1:]
        sys.argv = sys.argv[:idx]

    def extra_args(self):
        return None

    def __call__(self, *args, **kwargs):
        self.extract_extra_args()
        return super().__call__(*args, **kwargs)

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
            typer_app = super()
            is_main = kwargs.pop('main', False)
            if is_main:
                self._fix_help_text(kwargs)
            def decorator(func):
                # this registers the command with the app
                # upon app() invocation, registered commands are being transformed
                # from CommandInfo into click commands via typer.get_commend()
                x = typer_app.command(*args, **kwargs)(func)
                i = 0
                for cmd in self.registered_commands:
                    if cmd.callback == x:
                        self.registered_commands[i] = CommandInfo(self, cmd)
                        break
                    i += 1
                return x

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
