unit SerialLink;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

(*
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  Copyright 2022, Fabian Schillig
  Email: xorgmc@gmail.com

  Original by:
  Copyright 2018, Petrukhanov Yuriy
  Email:juraspb@mail.ru
  Home: https://github.com/juraspb/MusictoColor
*)

interface

uses
{$IFnDEF FPC}

{$ELSE}
    Windows, LCLIntf, LCLType, LMessages,
{$ENDIF}
  Classes, SysUtils;

type
  TOnErrorEvent = procedure(Sender: TObject; const Msg: string) of object;

  TSerialLink = class(TComponent)
  private
    FHandle: Cardinal;
    FDebug: Text;
    FActive: Boolean;
    FPort: string;
    FSpeed: integer;
    FError: integer;
    FOnError: TOnErrorEvent;
    procedure SetActive(val: Boolean);
    procedure SetPort(val: string);
    procedure SetSpeed(val: integer);
  protected
    procedure DoErrorEvent(const Msg: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Active: Boolean read FActive write SetActive;
    property Port: string read FPort write SetPort;
    property Speed: integer read FSpeed write SetSpeed;
    property Error: integer read FError;
    procedure Open;
    procedure Close;
    procedure SendBuffer(var SendBuff: array of byte);
    procedure ReceiveBuffer(var RcvBuff: array of char; ToReceive: Cardinal);
    function ReceiveInQue: integer;
    function SetTimeouts(ReadTotal: Cardinal): Boolean;
    property OnError: TOnErrorEvent read FOnError write FOnError;
  end;

implementation
{ TSerialLink }

const
  MAX_TRYNMB = 1;

procedure Delay(tiks : longint);
var  TCount,T1Count: longint;
begin
  TCount:=GetTickCount;
  Repeat
   T1Count:=GetTickCount;
   if TCount > T1Count then
   Begin
    TCount:=GetTickCount;
    T1Count:=GetTickCount;
   End;
  Until ((T1Count-TCount) > tiks);
end;

procedure TSerialLink.Close;
begin
  if not Active then Exit;
  try
    FileClose(FHandle); { *Konvertiert von CloseHandle* }
    CloseFile(FDebug);
  finally
    FActive:= False;
  end;
end;

constructor TSerialLink.Create(AOwner: TComponent);
begin
  inherited;
  FActive:= False;
  FError:= 0;
  FPort:= 'COM1';
  FSpeed:= 2400;
end;


destructor TSerialLink.Destroy;
begin
  Close;
  inherited;
end;

procedure TSerialLink.DoErrorEvent(const Msg: string);
begin
  if Assigned(OnError) then OnError(Self, Msg);
end;

procedure TSerialLink.Open;
var _DCB : TDCB;
begin
  {Open the port}
  FHandle := CreateFile(PChar(Port), GENERIC_READ+GENERIC_WRITE, 0, nil,
               OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  AssignFile(FDebug, 'debug.txt');
  Rewrite(FDebug);
  Writeln(FDebug, 'yo');
  if FHandle = INVALID_HANDLE_VALUE then
  begin
    DoErrorEvent('Cannot open port!');
    FError:= -1;
    Exit;
  end;
 try
  {Set port options}
  if not GetCommState(FHandle, _DCB) then
  begin
    DoErrorEvent('Cannot get port status!');
    FError:= -2;
    Exit;
  end;
  with _DCB do
  begin
    BaudRate := FSpeed;
    Flags := $00000001;
    ByteSize := DATABITS_8;
    Parity := NOPARITY;
    StopBits := TWOSTOPBITS;
  end;
  if not SetCommState(FHandle, _DCB) then
  begin
    DoErrorEvent('Cannot set port status!');
    FError:= -3;
    Exit;
  end;
  EscapeCommFunction(FHandle, SETDTR);
  if not SetTimeouts(10000) then Exit;
  FActive:= True;
  FError:= 0;
 finally
   if not FActive then begin
     CloseFile(FDebug);
    FileClose(FHandle); end; { *Konvertiert von CloseHandle* }
 end;
end;

procedure TSerialLink.SetActive(val: Boolean);
begin
  if val then Open else Close;
end;

procedure TSerialLink.SetPort(val: string);
begin
  if FPort = val then Exit;
  FPort:= val;
  if FActive then
  begin
    Close;
    Open;
  end;
end;

procedure TSerialLink.SetSpeed(val: integer);
begin
  if FSpeed = val then Exit;

  FSpeed:= val;
  if FActive then
  begin
    Close;
    Open;
  end;
end;

function TSerialLink.SetTimeouts(ReadTotal: Cardinal): Boolean;
var
  _CommTimeouts : TCommTimeouts;
begin
  Result:= False;
  with _CommTimeouts do
  begin
//    ReadIntervalTimeout:= 20;
    ReadIntervalTimeout:= 0;
    ReadTotalTimeoutMultiplier:= 4;
    ReadTotalTimeoutConstant:= ReadTotal;
    WriteTotalTimeoutMultiplier:= 0;
    WriteTotalTimeoutConstant:= 0;
  end;
  if not SetCommTimeouts(FHandle, _CommTimeouts) then
  begin
    DoErrorEvent('Cannot set port timeout');
    Exit;
  end;
  Result:= True;
end;

procedure TSerialLink.SendBuffer(var SendBuff: array of byte);
var
  written,ToSend,i: Cardinal;
  trynmb: Cardinal;
  dbg: Integer;
begin
  ToSend := 0;
  while (SendBuff[ToSend]<>254) do ToSend:=ToSend+1;
  ToSend:=ToSend+1;

  Write(FDebug, '[');
  for dbg:=0 To ToSend do begin
     Write(FDebug, IntToHex(SendBuff[dbg], 2));
     Write(FDebug, ',');
  end;
  Writeln(FDebug, ']');

  if ToSend>0 then
   begin
    for trynmb:= 1 to MAX_TRYNMB do
     begin
      if not WriteFile(FHandle, SendBuff, ToSend, written, nil) Or (written <> ToSend) then
      begin
        DoErrorEvent('Cannot write to port!');
        FError:= -4;
        Exit;
      end;
     end;
    FlushFileBuffers(FHandle);
    FError:= 0;
   end;
end;

procedure TSerialLink.ReceiveBuffer(var RcvBuff: array of char; ToReceive: Cardinal);
var
  rcvd: Cardinal;
begin
//  PurgeComm(FHandle,PURGE_RXCLEAR);
  if not ReadFile(FHandle, RcvBuff, ToReceive, rcvd, nil) then
   begin
    DoErrorEvent('Cannot read from port!');
    FError:= -5;
    Exit;
   end;
  if rcvd = 0 then
   begin
    DoErrorEvent('Port buffer is empty!');
    FError:= -6;
    Exit;
   end;
  PurgeComm(FHandle,PURGE_TXCLEAR+PURGE_RXCLEAR);
  FError:= 0;
end;

function TSerialLink.ReceiveInQue : integer;
var ComSt: TComStat;
    ComErrors: dword;
Begin
  ClearCommError(FHandle,ComErrors,Addr(ComSt));
  result:=ComSt.cbInQue;
End;

end.
