unit PngSpeedButton;

interface

uses
  Windows, Classes, Buttons, pngimage, PngFunctions;

type
  TPngSpeedButton = class(TSpeedButton)
  private
    FPngImage: TPngImage;
    FPngOptions: TPngOptions;
    FImageFromAction: Boolean;
    function PngImageStored: Boolean;
    procedure SetPngImage(const Value: TPngImage);
    procedure SetPngOptions(const Value: TPngOptions);
    procedure CreatePngGlyph;
    function HasValidPng: Boolean;
  protected
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
    procedure Paint; override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property PngImage: TPngImage read FPngImage write SetPngImage stored PngImageStored;
    property PngOptions: TPngOptions read FPngOptions write SetPngOptions default [pngBlendOnDisabled];
    property Glyph stored False;
    property NumGlyphs stored False;
  end;

implementation

uses
  Graphics, ActnList, PngButtonFunctions, PngImageList;

{ TPngSpeedButton }

constructor TPngSpeedButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPngImage := TPngImage.Create;
  FPngOptions := [pngBlendOnDisabled];
  FImageFromAction := False;
end;

destructor TPngSpeedButton.Destroy;
begin
  inherited Destroy;
  FPngImage.Free;
end;

procedure TPngSpeedButton.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited ActionChange(Sender, CheckDefaults);
  if Sender is TCustomAction then
    with TCustomAction(Sender) do begin
      //Copy image from action's imagelist
      if (PngImage.Empty or FImageFromAction) and (ActionList <> nil) and
        (ActionList.Images <> nil) and (ImageIndex >= 0) and (ImageIndex <
        ActionList.Images.Count) then begin
        CopyImageFromImageList(FPngImage, ActionList.Images, ImageIndex);
        CreatePngGlyph;
        FImageFromAction := True;
      end;
    end;
end;

procedure TPngSpeedButton.Paint;
var
  PaintRect: TRect;
  GlyphPos, TextPos: TPoint;
begin
  inherited Paint;

  if HasValidPng then begin
    Canvas.Handle := 0;
    Canvas.Font := Font;
    //Calculate the position of the PNG glyph
    CalcButtonLayout(Canvas, FPngImage, ClientRect, FState = bsDown, Down,
      Caption, Layout, Margin, Spacing, GlyphPos, TextPos, DrawTextBiDiModeFlags(0));
    PaintRect := Bounds(GlyphPos.X, GlyphPos.Y, FPngImage.Width, FPngImage.Height);

    if csLoading in ComponentState then Exit;

    if Enabled then
      DrawPNG(FPngImage, Canvas, PaintRect, [])
    else
      DrawPNG(FPngImage, Canvas, PaintRect, FPngOptions);
  end;
end;

procedure TPngSpeedButton.Loaded;
begin
  inherited Loaded;
  CreatePngGlyph;
end;

function TPngSpeedButton.PngImageStored: Boolean;
begin
  Result := not FImageFromAction;
end;

procedure TPngSpeedButton.SetPngImage(const Value: TPngImage);
begin
  //This is all neccesary, because you can't assign a nil to a TPngImage
  if Value = nil then begin
    FPngImage.Free;
    FPngImage := TPngImage.Create;
  end
  else begin
    FPngImage.Assign(Value);
  end;

  if HasValidPng then begin
    //To work around the gamma-problem
    if FPngImage.Header.ColorType in [COLOR_RGB, COLOR_RGBALPHA, COLOR_PALETTE] then
      FPngImage.Chunks.RemoveChunk(FPngImage.Chunks.ItemFromClass(TChunkgAMA));
  end;

  FImageFromAction := False;
  CreatePngGlyph;
  Repaint;
end;

procedure TPngSpeedButton.SetPngOptions(const Value: TPngOptions);
begin
  if FPngOptions <> Value then begin
    FPngOptions := Value;
    CreatePngGlyph;
    Repaint;
  end;
end;

procedure TPngSpeedButton.CreatePngGlyph;
var
  Bmp: TBitmap;
begin
  //Create an empty glyph, just to align the text correctly
  Bmp := TBitmap.Create;
  try
    Bmp.Width := FPngImage.Width;
    Bmp.Height := FPngImage.Height;
    Bmp.Canvas.Brush.Color := clBtnFace;
    Bmp.Canvas.FillRect(Rect(0, 0, Bmp.Width, Bmp.Height));
    Glyph.Assign(Bmp);
    NumGlyphs := 1;
  finally
    Bmp.Free;
  end;
end;

function TPngSpeedButton.HasValidPng: Boolean;
begin
  Result := (FPngImage <> nil) and not FPngImage.Empty;
end;

end.
