class TachometerInteraction extends Interaction config (MutatH0r);

// defined at initialization
var PlayerController PC;
var CRZMutator_Tachometer Owner;

// static
var Font MessageFont;
var Color TextColor, TextColorGreen, TextColorRed, BackgroundColor, VeloColor;

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
  local CRZPawn p;
  local CRZPlayerInput inp;
  local float x,y;
  local vector v;
  local string text;
  local bool canDoubleJump;

  p = CRZPawn(PC.Pawn);
  if (p == none)
    return;

  inp = CRZPlayerInput(PC.PlayerInput);

  if (!isJumping && p.Physics == PHYS_Walking)
    LastGroundPos = p.Location;
  else if (pc.Pawn.Physics == PHYS_Falling)
    isJumping = true;
  else if (isJumping && p.Physics == PHYS_Walking)
  {
    isJumping = false;
    LastGroundPos.Z = 0;
    v = p.Location;
    v.Z = 0;
    jumpDistance = VSize(v - LastGroundPos);
  }

  v.X = p.Velocity.X;
  v.Y = p.Velocity.Y;
  v.Z = 0;


  // draw box
  x = canvas.ClipX * 0.45;
  y = canvas.ClipY * 0.45;
  canvas.DrawColor = BackgroundColor;
  canvas.SetPos(x, y);
  canvas.DrawRect(95, 79);
  
  // draw H
  text = "H: " $ string(int(VSize(v) + 0.5));
  canvas.DrawColor = inp.Outer.DoubleClickDir == DCLICK_Done ? TextColorRed : TextColor; 
  canvas.Font = MessageFont;
  canvas.SetPos(x + 2, y + 2);
  canvas.DrawText(text, false, 1.0, 1.0);

  // draw V
  // from CRZPawn.DoJump():
  canDoubleJump = p.CanDoubleJump() && p.bAllowFallingMultiJump ? (p.Velocity.Z < p.DoubleJumpThreshold) : (Abs(p.Velocity.Z) < p.DoubleJumpThreshold);
  text = "V: " $ string(int(p.Velocity.Z + 0.5));
  canvas.DrawColor = (p.Physics == PHYS_Walking || p.MultiJumpRemaining == 0) ? TextColor : (canDoubleJump ? TextColorGreen : TextColor /*Red*/); 
  canvas.Font = MessageFont;
  canvas.SetPos(x + 2, y + 27);
  canvas.DrawText(text, false, 1.0, 1.0);

  // draw D  
  text = "D: " $ string(int(jumpDistance + 0.5));
  canvas.DrawColor = TextColor; 
  canvas.Font = MessageFont;
  canvas.SetPos(x + 2, y + 52);
  canvas.DrawText(text, false, 1.0, 1.0);

  // draw velocity vector line
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
  TextColorGreen=(R=0,G=255,B=0,A=128)  
  TextColorRed=(R=255,G=0,B=0,A=128)  
  BackgroundColor=(R=0, G=0, B=0, A=64)
  VeloColor=(R=255,G=255,B=0,A=128);
}
