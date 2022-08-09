unit FFTBase;

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
  Windows,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  FFTFilterConst;
{$R-}
type
  TFFTBase = class(TComponent)
  private
    { Private declarations }
   fWindowSize, tTlbSize: Integer;
   fSinTbl, fCosTbl     : PTbl;
   procedure InitSinCosTbl;
  protected
    { Protected declarations }
  public
    { Public declarations }
   procedure FFT( var F        :Pointer;
		  N, M          :integer;
		  const Inverse :boolean;
		  const Window  :Integer ); //N-size; F, M - N =2^M
   procedure simpleFFT( var F        :Pointer;
		  N, M          :integer;
		  const Inverse :boolean;
		  const Window  :Integer ); //N-size F, M - N =2^M
   procedure InitMem(WindowSize: Integer);
   procedure DelMem;
  published
    { Published declarations }
  end;

procedure Register;

implementation

{+private++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure TFFTBase.InitSinCosTbl;
var i :integer;
begin
 for i :=1 to 2*fWindowSize do
 begin
  fSinTbl[i] := (-1)*Sin(PI/i);
  fCosTbl[i] := Cos(PI/i);
 end;
end;
{-private----------------------------------------------------------------------}

{+PUBLIC+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
procedure TFFTBase.FFT( var F       :Pointer;
                    N, M          :integer;
                    const Inverse :boolean;
		    const Window  :Integer ); //N -size F, M - N =2^M
var U, Uo, W, T :TComplex;
    I,IP,J,K,L,LE,LE1,NV2,NM1 :integer;
    ReDummy, ImDummy :extended;

    procedure SetWindow(const Window: Integer);
    var i: Integer;
    begin
     if Not Inverse then //If not reverse
      case Window of  //0-rectangular//1-triangular//2-Haming
       0: begin  //0-rectangular
           {for i :=0 to N-1 do
             F[i].Re :=F[i].Re*1.2}
          end;
       1: begin //1-triangular
           for i :=0 to N-1 do begin
            if (i <= N div 2) then
             TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*i/(N/2)
            else TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*(N-i)/(N/2);
           end;
          end;
       2: begin //2-Hamming
           for i :=0 to N-1 do
	     TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*(0.54-0.46*cos(2*Pi*i/N))
          end;
       3: begin //3-Hann
           for i :=0 to N-1 do
	    TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*(1+cos(2*Pi*i/N))/2;
          end;
       4: begin //4-Blackman
	   for i :=0 to N-1 do
            TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*(0.42+0.5*cos(2*Pi*i/N)+0.08*cos(4*Pi*i/N))
          end;
      end;
    end;
begin

 InitMem(N);
 InitSinCosTbl;
 SetWindow(Window);

 NV2 :=N shr 1;
 NM1 :=N-1;
 J   :=1;
 if Inverse then
  for i :=0 to N-1 do
   TComplexArray(F^)[i].Im :=-TComplexArray(F^)[i].Im;

 for I :=1 to NM1 do begin
  if I<J then begin
   T      :=TComplexArray(F^)[J-1];
   TComplexArray(F^)[J-1] :=TComplexArray(F^)[I-1];
   TComplexArray(F^)[I-1] :=T;
  end;
  K :=NV2;
  while K < J do begin
   J :=J - K;
   K :=K shr 1;
  end;
  J :=J + K;
 end;
 for L :=1 to M do begin
  LE   :=2 shl (L-1);
  LE1  :=LE shr 1;
  U.Re :=1.0; U.Im :=0.0;
  W.Re :=fCosTbl[LE1];
  W.Im :=fSinTbl[LE1];
  for J :=1 to LE1 do begin
   I :=J;
   while I <= N do begin
    IP :=I + LE1;
    T.Re    :=TComplexArray(F^)[IP-1].Re * U.Re - TComplexArray(F^)[IP-1].Im * U.Im;
    T.Im    :=TComplexArray(F^)[IP-1].Re * U.Im + TComplexArray(F^)[IP-1].Im * U.Re;
    TComplexArray(F^)[IP-1].Re :=TComplexArray(F^)[I-1].Re - T.Re;
    TComplexArray(F^)[IP-1].Im :=TComplexArray(F^)[I-1].Im - T.Im;
    TComplexArray(F^)[I-1].Re:=TComplexArray(F^)[I-1].Re+T.Re;
    TComplexArray(F^)[I-1].Im:=TComplexArray(F^)[I-1].Im+T.Im;
    Inc(I,LE);
   end;
   Uo :=U;
   U.Re :=(Uo.Re * W.Re) - (Uo.Im * W.Im);
   U.Im :=(Uo.Re * W.Im) + (Uo.Im * W.Re);
  end;
 end;

 ImDummy :=1/Sqrt(N);
 if Inverse then ImDummy :=-ImDummy;
 ReDummy :=Abs(ImDummy);
 for I :=1 to N do
  begin
   TComplexArray(F^)[i-1].Re :=TComplexArray(F^)[i-1].Re*ReDummy;
   TComplexArray(F^)[i-1].Im :=TComplexArray(F^)[i-1].Im*ImDummy;
  end;

 if not Inverse then //Power Calculation C=SQRT(A^2+B^2) with -direct- FFT
  for i :=0 to N-1 do
   TComplexArray(F^)[i].Re :=sqrt(sqr(TComplexArray(F^)[i].Re)+sqr(TComplexArray(F^)[i].Im));
 DelMem; //Release memory
end;

procedure TFFTBase.InitMem(WindowSize: Integer);
begin
 fWindowSize:=WindowSize;
 tTlbSize:=(2*fWindowSize+1)*SizeOf(Single);
 fSinTbl:=AllocMem(tTlbSize);
 fCosTbl:=AllocMem(tTlbSize);
end;

procedure TFFTBase.DelMem;
begin
 FreeMem(fCosTbl, tTlbSize);
 FreeMem(fSinTbl, tTlbSize);
end;
{-PUBLIC-----------------------------------------------------------------------}

procedure Register;
begin
  RegisterComponents('MyControls', [TFFTBase]);
end;

procedure TFFTBase.simpleFFT(var F: Pointer; N, M: integer;
  const Inverse: boolean; const Window: Integer);
var U, Uo, W, T :TComplex;
    I,IP,J,K,L,LE,LE1,NV2,NM1 :integer;
    ReDummy, ImDummy :extended;

    procedure SetWindow(const Window: Integer);
    var i: Integer;
    begin
     if Not Inverse then //If Not reversed
      case Window of  //0-rectangular//1-triangular//2-Hamming
       0: begin  //0-Rectangular
           {for i :=0 to N-1 do
             F[i].Re :=F[i].Re*1.2}
          end;
       1: begin //1-Triangular
           for i :=0 to N-1 do begin
            if (i <= N div 2) then
             TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*i/(N/2)
            else TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*(N-i)/(N/2);
           end;
          end;
       2: begin //2-Hamming
           for i :=0 to N-1 do
	     TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*(0.54-0.46*cos(2*Pi*i/N))
          end;
       3: begin //3-Hann
           for i :=0 to N-1 do
	    TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*(1+cos(2*Pi*i/N))/2;
          end;
       4: begin //4-Blackman
	   for i :=0 to N-1 do
            TComplexArray(F^)[i].Re :=TComplexArray(F^)[i].Re*(0.42+0.5*cos(2*Pi*i/N)+0.08*cos(4*Pi*i/N))
          end;
      end;
    end;
begin
 InitMem(N);
 InitSinCosTbl;
 SetWindow(Window);

 NV2 :=N shr 1;
 NM1 :=N-1;
 J   :=1;
 if Inverse then
  for i :=0 to N-1 do
   TComplexArray(F^)[i].Im :=-TComplexArray(F^)[i].Im;

 for I :=1 to NM1 do begin
  if I<J then begin
   T      :=TComplexArray(F^)[J-1];
   TComplexArray(F^)[J-1] :=TComplexArray(F^)[I-1];
   TComplexArray(F^)[I-1] :=T;
  end;
  K :=NV2;
  while K < J do begin
   J :=J - K;
   K :=K shr 1;
  end;
  J :=J + K;
 end;
 for L :=1 to M do begin
  LE   :=2 shl (L-1);
  LE1  :=LE shr 1;
  U.Re :=1.0; U.Im :=0.0;
  W.Re :=fCosTbl[LE1];
  W.Im :=fSinTbl[LE1];
  for J :=1 to LE1 do begin
   I :=J;
   while I <= N do begin
    IP :=I + LE1;
    T.Re    :=TComplexArray(F^)[IP-1].Re * U.Re - TComplexArray(F^)[IP-1].Im * U.Im;
    T.Im    :=TComplexArray(F^)[IP-1].Re * U.Im + TComplexArray(F^)[IP-1].Im * U.Re;
    TComplexArray(F^)[IP-1].Re :=TComplexArray(F^)[I-1].Re - T.Re;
    TComplexArray(F^)[IP-1].Im :=TComplexArray(F^)[I-1].Im - T.Im;
    TComplexArray(F^)[I-1].Re:=TComplexArray(F^)[I-1].Re+T.Re;
    TComplexArray(F^)[I-1].Im:=TComplexArray(F^)[I-1].Im+T.Im;
    Inc(I,LE);
   end;
   Uo :=U;
   U.Re :=(Uo.Re * W.Re) - (Uo.Im * W.Im);
   U.Im :=(Uo.Re * W.Im) + (Uo.Im * W.Re);
  end;
 end;
 ImDummy :=1/Sqrt(N);
 if Inverse then ImDummy :=-ImDummy;
 ReDummy :=Abs(ImDummy);
 for I :=1 to N do
  begin
   TComplexArray(F^)[i-1].Re :=TComplexArray(F^)[i-1].Re*ReDummy;
   TComplexArray(F^)[i-1].Im :=TComplexArray(F^)[i-1].Im*ImDummy;
  end;
 DelMem; //Release Memory
end;

end.
