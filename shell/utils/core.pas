{
    core.pas - Timmy-related core utilities for Timmy Interactive Shell

    Copyright (C) 2018 42tm Team <fourtytwotm@gmail.com>

    This file is part of Timmy Interactive Shell.

    Timmy Interactive Shell is free software: you can redistribute it
    and/or modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation, either version 3
    of the License, or (at your option) any later version.
}
{$mode ObjFPC} {$H+}
Unit Core;

Interface

Uses
     Crt, SysUtils, StrUtils,
     ArgsParser, Logger in '../logger/logger.pas',
     Timmy_Debug in '../../variants/timmy_debug.pas';
Type
    TExitCode = Word;
Var
    Env: Record  // Shell environment variables
           // Array to store user's entered inputs (in current session)
           // Commonly refered to as the input history
             InputHis: TStrArray;
           // Option whether to interpret backslash in user's input
             ItprBackslash: Boolean;
           // True if the Shell is executing inputs from file
             ExecF: Boolean;
           // Exit code of last executed command
             ExitCode: TExitCode;
         End;

    UserInput: String;  // User's input to the shell
    TestSubj: TTimmy;   // Subject TTimmy instance
    ShLog: TLogger;     // Logger for Timmy Interactive Shell

    InputRec: Record    // User input data record
                Cmd: String;       // Da command
                Args: TStrArray;   // Da arguments
              End;

    InstanceName: String;  // Name of the test subject instance
    Initiated: Boolean;    // State of initialization of the test subject

    // Input recording mechanism
      Recorder: Record
                  Recording: Boolean;
                  RecdInps: TStrArray;
                End;

    // For exec command
      UserInput2: String;
      ExecFilePaths: TStrArray;

    // Arguments parsing variables
      ArgParser: TArgumentParser;
      OutParse: TParseResult;

// Happy little function to print a colored dot
// shell/inc/frontend/jam.pp
Procedure Jam(DotColor: Byte);

(* Main stuff *)
Function ShellExec(ShellInput: String): TExitCode;
Function PrintHelp(ManName: String):    TExitCode;
Function ProcessRecord:                 TExitCode;
Function Exec(FName: String):           TExitCode;
Function Init:                          TExitCode;
Function RenameBot:                     TExitCode;

Implementation

{$Include ../inc/frontend/jam.pp}

{ Process the user's input (core.pas -> UserInput) before executing }
Procedure ProcessInput;
Var
    FlagSplit: TStrArray;
Begin
    If UserInput = '' then Exit;

    // Add command to input history, if this input is not the same as the
    // previous input, and the Shell is not executing from file
      If ( ( (Length(Env.InputHis) > 0)
          and (not (UserInput = Env.InputHis[High(Env.InputHis)])) )
          or (Length(Env.InputHis) = 0) ) and (not Env.ExecF)
               then Begin
                      SetLength(Env.InputHis, Length(Env.InputHis) + 1);
                      Env.InputHis[High(Env.InputHis)] := UserInput;
                    End;

    // Record input, if the recorder is running
      If Recorder.Recording
        then Begin
               SetLength(Recorder.RecdInps, Length(Recorder.RecdInps) + 1);
               Recorder.RecdInps[High(Recorder.RecdInps)] := UserInput;
             End;

    // Get command and arguments passed to that command in the user input
    // for ShellExec()
      FlagSplit := StrSplit(UserInput, ' ', Env.ItprBackslash);
      InputRec.Cmd := LowerCase(FlagSplit[0]);
      InputRec.Args := Copy(FlagSplit, 1, High(FlagSplit));

    Env.ExitCode := ShellExec;  // Execute the input and get the exit code

    // Remove the input from input history because it has an invalid command
      If (Env.ExitCode = 5) and (OutParse.HasArgument('record-less'))
          and (not Env.ExecF)
        then SetLength(Env.InputHis, Length(Env.InputHis) - 1);

    // Remove the input from recorder because it is invalid
      If (Env.ExitCode mod 10 > 2) and (Recorder.Recording)
        then SetLength(Recorder.RecdInps, Length(Recorder.RecdInps) - 1);
End;

{
    Determine the command and execute

    Return:
        [TExitCode -> Word] Exit code returned by the command executed
}
Function ShellExec: TExitCode: TExitCode;
Begin
    Case InputRec.Cmd of
      'exit', 'quit': Begin
                        ShLog.Log(TLogger.INFO, 'Quitting Shell session');
                        TextColor(7); Halt;
                      End;
      'clear': Begin ClrScr; Exit(10); End;
      'help': If Length(InputRec.Args) = 0
                then Exit(PrintHelp('shell'))
                else Exit(PrintHelp(InputRec.Args[0]));
      'record': Exit(ProcessRecord);
      'exec': If Length(InputRec.Args) = 0
                then Begin
                       ShLog.Put(TLogger.ERROR, 'exec: No input file.');
                       Exit();
                     End;
                else Begin
                       ExecFilePaths := InputRec.Args;  // To avoid conflict
                       For UserInput2 in ExecFilePaths do Exec(UserInput2);
                     End;
      'stat': Begin
              End;
      'set': Begin
             End;
      'echo': Begin
              End;
      'rename': Exit(RenameBot);
      'init': If not Initiated then Init
                else ShLog.Put(TLogger.INFO, 'Instance already initiated');
      'add': Begin

             End;
      Else Begin
             ShLog.Put(TLogger.ERROR,
                       'Invalid command ''' + InputRec.Cmd + '''');
             Exit(5);
           End;
    End;

    Exit(0);
End;

{$Include ../inc/cmd/help.pp}    // The help command
{$Include ../inc/cmd/record.pp}  // The record command
{$Include ../inc/cmd/exec.pp}    // The exec command
{$Include ../inc/cmd/rename.pp}  // The rename command
{$Include ../inc/cmd/init.pp}    // The init command

End.
