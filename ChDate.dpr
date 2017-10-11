program ChDate;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, IniFiles, crc32, DateUtils, Base64;
const
  TAB = #9;
  APO = #39;
var
 Option1,Option2,Option3, Option4 : string;
 f: TFileStream;
 fout: TFileStream;
 fo: Text;
 buffer: array [0..512*1024-1] of byte;
  IniFile: TMemIniFile;
  IniName: string;
  BuildNmbr: Integer;
// option: string;
 s: string;
 dts: string;
 i: Integer;
 j: Integer;
 k: Integer;
 addr: Integer;
 crc: Cardinal;
 siz: Integer;
 utc: TDateTime;
 split: Boolean;
// InputFile: File;
// OutputFile: File;

function FirstDayOfDST(): TDateTime;
begin
  Result:=EncodeDateTime(YearOf(Now),4,1,0,0,0,0);
  Result:=IncDay(Result,-1);
  while(DayOfTheWeek(Result)<>7) do begin
    Result:=IncDay(Result,-1);
  end;
end;

function LastDayOfDST(): TDateTime;
begin
  Result:=EncodeDateTime(YearOf(Now),11,1,0,0,0,0);
  Result:=IncDay(Result,-1);
  while(DayOfTheWeek(Result)<>7) do begin
    Result:=IncDay(Result,-1);
  end;
  Result:=IncDay(Result,-1);
end;

function IsDayInDTS(dt: TDateTime): Boolean;
begin
  Result:=(CompareDate(FirstDayOfDST,dt)<=0) and (CompareDate(LastDayOfDST,dt)>=0);
end;

begin
  try
    Option1:=ParamStr(1);
    Option2:=ParamStr(2);
  	Option3:=ParamStr(3);
    Option4:=ParamStr(4);
    if (Option2='') then begin
      f:=TFileStream.Create(Option1,fmOpenReadWrite);
      f.Seek(f.Size-1,0);
      f.Read(buffer,1);
      f.Seek(f.Size-1,0);
      f.WriteBuffer(buffer,1);
      f.Free;
      writeln(Format('%s updated',[Option1]));
    end else begin
    	if (Copy(Option2,1,5)='-crc=') then begin
	      f:=TFileStream.Create(Option1,fmOpenRead);
        s:=Copy(Option2,6,Length(Option2));
        AssignFile(fo,s);
        Rewrite(fo);
        f.Seek(0,0);
        f.ReadBuffer(buffer,f.Size);
        crc:=CalculateCrc32(buffer,f.Size);
        s:=IntToHex(crc,8);
      	Write(fo,s);
        Writeln('CRC='+s);
        CloseFile(fo);
        f.Free;
      end;
    	if (Copy(Option2,1,8)='-crcsiz=') then begin
	      f:=TFileStream.Create(Option1,fmOpenRead);
        s:=Copy(Option2,9,Length(Option2));
        AssignFile(fo,s);
        Rewrite(fo);
      	s:='';
        siz:=0;
        if (Copy(Option3,1,5)='-siz=') then begin
          s:=Copy(Option3,6,Length(Option3));
          siz:=StrToIntDef(s,0);
        end;
        f.Seek(0,0);
        if (siz=0) then begin
          siz:=f.Size;
        end;
        f.ReadBuffer(buffer,siz);
        crc:=CalculateCrc32(buffer,siz);
        s:=IntToHex(crc,8)+';';
      	Write(fo,s);
        Writeln('CRC='+s);
        s:=IntToStr(siz);
      	Write(fo,s);
        Writeln('size='+s);
        CloseFile(fo);
        f.Free;
      end;
    	if (Copy(Option2,1,5)='-siz=') then begin
	      f:=TFileStream.Create(Option1,fmOpenRead);
        s:=Copy(Option2,6,Length(Option2));
        AssignFile(fo,s);
        Rewrite(fo);
        f.Seek(0,0);
        s:=IntToStr(f.Size);
      	Write(fo,s);
        Writeln('size='+s);
        CloseFile(fo);
        f.Free;
      end;
    	if (Copy(Option2,1,5)='-hdr=') then begin
	      f:=TFileStream.Create(Option1,fmOpenRead);
        s:=Copy(Option2,6,Length(Option2));
        fout:=TFileStream.Create(s,fmCreate);
        if Copy(Option3,1,2)='0x' then
          Option3:='$'+Copy(Option3,3,Length(Option3));
        if TryStrToInt(Option3,addr) then begin
          f.Seek(addr,0);
          f.ReadBuffer(buffer,40);
          fout.WriteBuffer(buffer,40);
          writeln('Descriptor file ok');
        end else begin
          Writeln('Wrong address');
        end;
        fout.Free;
        f.Free;
      end;
    	if (Copy(Option2,1,8)='-hdrb64=') then begin
	      f:=TFileStream.Create(Option1,fmOpenRead);
        s:=Copy(Option2,9,Length(Option2));
        AssignFile(fo,s);
        Rewrite(fo);
        if Copy(Option3,1,2)='0x' then
          Option3:='$'+Copy(Option3,3,Length(Option3));
        if TryStrToInt(Option3,addr) then begin
          f.Seek(addr,0);
          f.ReadBuffer(buffer,40);
          s:=B64Encode(buffer, 40);
          Write(fo,s);
        end else begin
          Writeln('Wrong address');
        end;
        CloseFile(fo);
        f.Free;
      end;
      if (Copy(Option2,1,7)='-base64') then begin
      	f:=TFileStream.Create(Option1, fmOpenRead);
      	s:='';
        siz:=0;
        if (Copy(Option4,1,5)='-siz=') then begin
          s:=Copy(Option4,6,Length(Option4));
          siz:=StrToIntDef(s,0);
        end;
        split:=False;
        if (Copy(Option4,1,10)='-splitsiz=') then begin
          s:=Copy(Option4,11,Length(Option4));
          siz:=StrToIntDef(s,0);
          split:=True;
        end;
        if (split and (siz>0)) then begin
        	i:=0;
          k:=f.Size div siz;
          if (f.Size mod siz)>0 then
	          Inc(k);
          while (i<k) do begin
            dts:=Format('%s.b%2.2d',[Option3,i]);
            AssignFile(fo,dts);
            Rewrite(fo);
            f.Seek(i*siz,0);
            j:= f.Size - i*siz;
            if ( j >siz ) then begin
            	f.ReadBuffer(buffer,siz);
	            s:=B64Encode(buffer,siz);
            end else begin
            	f.ReadBuffer(buffer,j);
	            s:=B64Encode(buffer,j);
            end;
            Write(fo,s);
            Writeln(dts);
            CloseFile(fo);
            inc(i);
          end;
        end else begin
          AssignFile(fo,Option3);
          Rewrite(fo);
          f.ReadBuffer(buffer,f.Size);
          if (siz=0) then begin
            siz:=f.Size;
          end;
          if (siz>f.Size) then
            siz:=f.Size;
          s:=B64Encode(buffer, siz);
          Write(fo,s);
	        CloseFile(fo);
        end;
        Writeln('Base64 ok');
        f.Free;
      end;
      if (Copy(Option2,1,9)='-base64r') then begin
        f:=TFileStream.Create(Option1, fmOpenRead);
        AssignFile(fo,Option3);
        Rewrite(fo);
        f.ReadBuffer(buffer,f.Size);
        s:=B64Decode(buffer,f.Size);
        Write(fo,s);
        CloseFile(fo);
        f.Free;
      end;
      if (Copy(Option2,1,10)='-incbuild=') then begin
        IniName:=Copy(Option2,11,Length(Option2));
        IniFile := TMemIniFile.Create(IniName);
        BuildNmbr:= IniFile.ReadInteger('Compilation','Build',0);
        Inc(BuildNmbr);
        writeln('option incbuild');
//        f:=TFileStream.Create(par,fmCreate);
        AssignFile(fo,Option1);
        Rewrite(fo);
        WriteLn(fo,'/*');
        WriteLn(fo,' * @file idsec.c');
        Writeln(fo,' * @author  Miros³aw Lach');
        Writeln(fo,' * @version V.1.0');
        if (IsDayInDTS(Now)) then begin
	        utc:=UnixToDateTime(DateTimeToUnix(Now)-2*60*60);
        end else begin
	        utc:=UnixToDateTime(DateTimeToUnix(Now)-1*60*60);
        end;
        DateTimeToString(dts,'yy-mm-dd hh:nn:ss',utc);
        WriteLn(fo,' * @date '+dts+'UTC');
        WriteLn(fo,' * @brief Plik identyfikuj¹cy program. Generowany przez skrypt ChDate.exe');
        WriteLn(fo,' * @copyright');
        DateTimeToString(dts,'yyyy',utc);
        WriteLn(fo,' * <h2><center>&copy; COPYRIGHT '+dts+' Miroslaw Lach</center></h2>');
        WriteLn(fo,' *');
        WriteLn(fo,' */');
        WriteLn(fo,'#include "idsec.h"');
        WriteLn(fo,' __attribute__((section(".idsec"))) const IdSoft_t IDSoft={');
        WriteLn(fo,TAB+'{');
        DateTimeToString(dts,'yymmddhhnnss',utc);
        k:=Length(dts);
        for i:=1 to k do begin
          WriteLn(fo,TAB+TAB+APO+dts[i]+APO+Format(' ^ SECKEY%d,',[i-1]));
        end;
        WriteLn(fo,TAB+TAB+'0,');
        WriteLn(fo,TAB+'},');
        WriteLn(fo,TAB+'{');
        dts:=Format('%6.6d',[BuildNmbr]);
        for i:=1 to Length(dts) do begin
          WriteLn(fo,TAB+TAB+APO+dts[i]+APO+Format(' ^ SECKEY%d,',[i+k-1]));
        end;
        WriteLn(fo,TAB+TAB+'0,');
        WriteLn(fo,TAB+'},');
        WriteLn(fo,TAB+'{');
        k:=k+Length(dts);
        for i:=1 to 16 do begin
          WriteLn(fo,TAB+TAB+Format('SECKEY%d,',[i+k-1]));
        end;
        WriteLn(fo,TAB+'},');
        WriteLn(fo,'};');
        WriteLn(fo,'');
        WriteLn(fo,'void ReadProcessorID(unsigned long int *id){');
        WriteLn(fo,TAB+'id[0]=*((unsigned long int *)(0x1FFFF7E8));');
        WriteLn(fo,TAB+'id[1]=*((unsigned long int *)(0x1FFFF7E8+4));');
        WriteLn(fo,TAB+'id[2]=*((unsigned long int *)(0x1FFFF7E8+8));');
        WriteLn(fo,'}');
        WriteLn(fo,'');
        WriteLn(fo,'');
//        WriteLn(fo,'unsigned char DummyIDSoft(void){');
//        WriteLn(fo,TAB+'return IDSoft.SoftTimeStamp[0];');
//        WriteLn(fo,'}');
//        WriteLn(fo,'');
        WriteLn(fo,'');
        WriteLn(fo,'');
        CloseFile(fo);
        IniFile.WriteInteger('Compilation','Build',BuildNmbr);
        IniFile.UpdateFile;
        IniFile.Free;
      end;
    end;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
