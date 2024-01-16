// PDB file format from
// http://deposit.rcsb.org/adit/docs/pdb_atom_format.html

// atom color coding from
// http://mrdoob.github.com/three.js/examples/js/loaders/PDBLoader.js
// part of ThreeJS "molecules" demo:
// http://mrdoob.github.com/three.js/examples/css3d_molecules.html

unit MolHero.ImportPDB;

interface

uses
  MolHero.MoleculeModel, System.Types;

function GetMoleculeFromStrings(const SL: TStringDynArray; const M: TMolecule): Boolean;

implementation

uses
  System.Classes, System.SysUtils, IOUtils, MolHero.Utils, MolHero.FormRes;

function ReadStringsFromFile(const AFileName: string): TStringDynArray;
begin
  if TFile.Exists(AFileName) then
    Result := TFile.ReadAllLines(AFileName)
  else
    Result := nil;
end;

function ExtrAtomKind(const S: string): Integer;
begin
  try
    Result := ElementSymbolToAtomicNr(UpperCase(Trim(S)));
  except
    Result := -1;
  end;
end;

function ExtrAtomCoord(S: string): double;
begin
  S := Trim(S);
  if not TryStrToFloat(S, Result) then
  begin
    S := StringReplace(S,'.',',',[]);
    Result := StrToFloat(S);
  end;
end;

procedure TranslateAtoms(const M: TMolecule; MinX, MinY, MinZ, MaxX, MaxY, MaxZ: double);
var
  DeltaX, DeltaY, DeltaZ: Double;
  I: Integer; AD: TAtomData;
begin
  DeltaX := (MaxX - MinX)/2 + MinX;
  DeltaY := (MaxY - MinY)/2 + MinY;
  DeltaZ := (MaxZ - MinZ)/2 + MinZ;

  for I := 0 to M.Atoms.Count-1 do
  begin
    AD := M.Atoms[I];
    AD.Pos.X := AD.Pos.X - DeltaX;
    AD.Pos.Y := AD.Pos.Y - DeltaY;
    AD.Pos.Z := AD.Pos.Z - DeltaZ;
  end;
end;

function GetMoleculeFromStrings(const SL: TStringDynArray; const M: TMolecule): Boolean;
var
  S: string;
  I, J: Integer;
  AD: TAtomData;
  BD: TBondData;
  E: string;
  BS: string;
  MinX, MinY, MinZ, MaxX, MaxY, MaxZ: Double;
  IsFirstAtom: Boolean;
begin
  Result := false;
  MinX := 0;
  MinY := 0;
  MinZ := 0;
  MaxX := 0;
  MaxY := 0;
  MaxZ := 0;

  if SL <> nil then
  begin

    IsFirstAtom := True;
    for I := 0 to Length(SL)-1 do
    begin
      S := SL[I];

      if (Copy(S,1,4) = 'ATOM') or (Copy(S,1,6) = 'HETATM') then
      begin
        E := Trim(Copy(S,77,2));
        if E = '' then
          E := Trim(Copy(S,13,4));
        AD.Symbol := E;

        AD.AtomKind := ExtrAtomKind(E);

        AD.Pos.X := ExtrAtomCoord(Copy(S,31,8));
        AD.Pos.Y := ExtrAtomCoord(Copy(S,39,8));
        AD.Pos.Z := ExtrAtomCoord(Copy(S,47,8));

        if IsFirstAtom then
        begin
          MinX := AD.Pos.X;
          MinY := AD.Pos.Y;
          MinZ := AD.Pos.Z;
          MaxX := AD.Pos.X;
          MaxY := AD.Pos.Y;
          MaxZ := AD.Pos.Z;
        end
        else
        begin
          if AD.Pos.X < MinX then MinX := AD.Pos.X;
          if AD.Pos.Y < MinY then MinY := AD.Pos.Y;
          if AD.Pos.Z < MinZ then MinZ := AD.Pos.Z;
          if AD.Pos.X > MaxX then MaxX := AD.Pos.X;
          if AD.Pos.Y > MaxY then MaxY := AD.Pos.Y;
          if AD.Pos.Z > MaxZ then MaxZ := AD.Pos.Z;
        end;

        IsFirstAtom := False;

        M.Atoms.Add(AD);
      end;

      if copy(S,1,6) = 'CONECT' then
      begin
        BD.IdStart := StrToInt(Copy(S,7,5))-1;

        for J := 0 to 3 do
        begin
          BS := Trim(copy(S,12+5*J,5));
          if BS <> '' then
          begin
            BD.IdEnd := StrToInt(BS)-1;
            if BD.IdEnd > 0 then
              M.Bonds.Add(BD);
          end;
        end;
      end;
    end;

    Result := True;

    if not IsFirstAtom then
      TranslateAtoms(M, MinX, MinY, MinZ, MaxX, MaxY, MaxZ);

  end;
end;

end.
