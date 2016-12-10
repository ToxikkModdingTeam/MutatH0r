class TachometerInteraction extends Interaction config (MutatH0r);

// defined at initialization
var PlayerController PC;
var CRZMutator_Tachometer Owner;

// static
var Font MessageFont;
var Color TextColor, BackgroundColor, VeloColor;

// instance
var config bool Disabled;
var vector LastGroundPos;
var bool isJumping;
var float jumpDistance;

static function TachometerInteraction Create(CRZMutator_Tachometer theOwner, PlayerController controller, optional bool bReturnExisting=true)
{
  local TachometerInteraction newInt;
  local int i;
 
  if (bReturnExisting)
  {
    for (i=0; i<controller.Interactions.length; i++)
    {
      if (controller.Interactions[i].class == default.class)
        return TachometerInteraction(controller.Interactions[i]);
    }
  }
 
  newInt = new(LocalPlayer(controller.Player).ViewportClient) default.class;
  LocalPlayer(controller.Player).ViewportClient.InsertInteraction(newInt, 0);
  controller.Interactions.AddItem(newInt);
  newInt.Owner = theOwner;
  return newInt;
}
 
function Initialized()
{
  super.Initialized();
  PC = GameViewportClient(Outer).GetPlayerOwner(0).Actor;
}

exec function ShowTacho(bool show)
{
  self.Disabled = !show;
  self.SaveConfig();
}

event PostRender(Canvas canvas)
{
  local CRZHud wrapper;

  super.PostRender(canvas);

  if (Disabled)
    return;
  if (Owner == None) // actor destroyed when match is over
    return;
  wrapper = CRZHud(PC.myHUD);
  if (wrapper == None || wrapper.CurrentHudMode == HM_Intro)
    return;

  RenderTickRate(canvas);
}

function RenderTickRate(Canvas canvas)
{
  local float x,y;
  local string text;
  local vector v;

  if (pc.Pawn == none)
    return;

  if (!isJumping && pc.Pawn.Physics == PHYS_Walking)
    LastGroundPos = pc.Pawn.Location;
  else if (pc.Pawn.Physics == PHYS_Falling)
    isJumping = true;
  else if (isJumping && pc.Pawn.Physics == PHYS_Walking)
  {
    isJumping = false;
    jumpDistance = VSize(pc.pawn.location - LastGroundPos);
  }

  v.X = pc.Pawn.Velocity.X;
  v.Y = pc.Pawn.Velocity.Y;
  v.Z = 0;

  text = "S: " $ string(int(VSize(v) + 0.5)) $ "\n"
    $ "D: " $ string(int(jumpDistance + 0.5));

  // draw box
  x = canvas.ClipX * 0.45;
  y = canvas.ClipY * 0.45;
  canvas.DrawColor = BackgroundColor;
  canvas.SetPos(x, y);
  canvas.DrawRect(85, 55);
  
  // draw number
  canvas.DrawColor = TextColor; 
  canvas.Font = MessageFont;
  canvas.SetPos(x + 2, y + 2);
  canvas.DrawText(text, false, 1.0, 1.0);

  v = v << PC.Rotation;
  canvas.Draw2DLine(Canvas.ClipX / 2, Canvas.ClipY / 2, Canvas.ClipX / 2 + v.Y/5, Canvas.ClipY / 2 - v.X/5, VeloColor);
}

event NotifyGameSessionEnded()
{
  super.NotifyGameSessionEnded();
  Owner = None;
  PC = None;
}

DefaultProperties
{
  MessageFont=Font'UI_Fonts.Fonts.UI_Fonts_Positec18'
  TextColor=(R=255,G=255,B=255,A=128)  
  BackgroundColor=(R=0, G=0, B=0, A=64)
  VeloColor=(R=255,G=255,B=0,A=128);
}
