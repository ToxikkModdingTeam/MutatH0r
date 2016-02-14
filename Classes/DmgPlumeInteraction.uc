class DmgPlumeInteraction extends Interaction;

// defined at initialization
var GameViewportClient Viewport;
var PlayerController PC;
var DmgPlumeActor Owner;

// static
var Font TextFont;
var float TimeToLive;
var float Scale;
var Color DmgBelow20;
var Color DmgBelow50;
var Color DmgBelow100;
var Color Dmg100;
var Color Black;
var LinearColor GlowColor;
var Vector2d GlowOuterRadius;
var Vector2d GlowInnerRadius;
var FontRenderInfo fontRenderInfo;


static function DmgPlumeInteraction Create(DmgPlumeActor owner, PlayerController PC, optional bool bReturnExisting=true)
{
  local DmgPlumeInteraction newInt;
  local int i;
 
  if (bReturnExisting)
  {
    for (i=0; i<PC.Interactions.length; i++)
    {
      if (PC.Interactions[i].class == default.class)
        return DmgPlumeInteraction(PC.Interactions[i]);
    }
  }
 
  newInt = new(LocalPlayer(PC.Player).ViewportClient) default.class;
  LocalPlayer(PC.Player).ViewportClient.InsertInteraction(newInt, 0);
  PC.Interactions.InsertItem(0, newInt);
  newInt.Owner = owner;
  return newInt;
}
 
function Initialized()
{
  Viewport = GameViewportClient(Outer);
  PC = Viewport.GetPlayerOwner(0).Actor;
  FontRenderInfo = class'Canvas'.static.CreateFontRenderInfo(false, false, GlowColor, GlowOuterRadius);
}
  
event PostRender(Canvas canvas)
{
  local int i;
  local vector pos;
  local Vector2D textSize;
  local PlumeSpriteInfo plume;
  local int alpha;

  if (Owner.Plumes.Length == 0)
    return;

  for (i=0; i<Owner.Plumes.Length; i++)
  {
    plume = Owner.Plumes[i];
    pos = canvas.Project(plume.Location);
    pos.X += plume.SpeedX * plume.Age;
    pos.Y += -plume.SpeedY * plume.Age + 80 * plume.Age * plume.Age;

    if (pos.X < 0 || pos.X >= canvas.ClipX || pos.Y < 0 || pos.Y >= canvas.ClipY)
      continue;
   
    canvas.Font = TextFont;
    canvas.TextSize(string(plume.Value), textSize.X, textSize.Y, Scale, Scale);
    if (pos.X + textSize.X / 2 + 1 >= canvas.ClipX)
      continue;

    alpha = int(255.0 * fclamp(1.0 - (plume.Age-0.5)/TimeToLive, 0, 1));

    canvas.DrawColor = Black;
    canvas.DrawColor.A = alpha / 4;
    canvas.SetPos(pos.X - textSize.X/2 - 1, pos.Y - textSize.Y/2 - 1);
    canvas.DrawText(string(plume.Value), false, Scale, Scale);
    canvas.SetPos(pos.X - textSize.X/2 + 1, pos.Y - textSize.Y/2 - 1);
    canvas.DrawText(string(plume.Value), false, Scale, Scale);
    canvas.SetPos(pos.X - textSize.X/2 - 1, pos.Y - textSize.Y/2 + 1);
    canvas.DrawText(string(plume.Value), false, Scale, Scale);
    canvas.SetPos(pos.X - textSize.X/2 + 1, pos.Y - textSize.Y/2 + 1);
    canvas.DrawText(string(plume.Value), false, Scale, Scale);

    canvas.DrawColor = GetColor(plume);
    canvas.DrawColor.A = alpha;
    canvas.SetPos(pos.X - textSize.X/2, pos.Y - textSize.Y/2);
    canvas.DrawText(string(plume.Value), false, Scale, Scale, FontRenderInfo);
  }
}

simulated function Color GetColor(PlumeSpriteInfo plume)
{
  local Color col;
  if (plume.Value <= 20)
    col = DmgBelow20;
  else if (plume.Value <= 50)
    col = DmgBelow50;
  else if (plume.Value < 100)
    col = DmgBelow100;
  else
    col = Dmg100;
  return col;
}

event NotifyGameSessionEnded()
{
  Disable('Tick');
  Owner = None;
  PC = None;
  Viewport = None;

  super.NotifyGameSessionEnded();
}

DefaultProperties
{
  TimeToLive = 1.5;
  Scale = 0.8;
  TextFont=Font'crzgfx.Font_Jupiter_DF'
  Black = (R=0,G=0,B=0,A=255);
  DmgBelow20 = (R=255,G=255,B=255,A=255);
  DmgBelow50 = (R=255,G=255,B=64,A=255);
  DmgBelow100 = (R=166,G=255,B=166,A=255);
  Dmg100 = (R=255,G=128,B=128);

  GlowColor = (R=1,G=1,B=1,A=1.0);
  GlowOuterRadius = (X=1,Y=0.6);
}
