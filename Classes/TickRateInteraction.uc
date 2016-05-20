class TickRateInteraction extends Interaction config (MutatH0r);

// defined at initialization
var PlayerController PC;
var CRZMutator_TickRate Owner;

// static
var Font MessageFont;
var Color TextColorGreen, TextColorYellow, TextColorRed, TextColorWhite;
var Color BackgroundColor;

// instance
var config bool Disabled;

static function TickRateInteraction Create(CRZMutator_TickRate theOwner, PlayerController controller, optional bool bReturnExisting=true)
{
  local TickRateInteraction newInt;
  local int i;
 
  if (bReturnExisting)
  {
    for (i=0; i<controller.Interactions.length; i++)
    {
      if (controller.Interactions[i].class == default.class)
        return TickRateInteraction(controller.Interactions[i]);
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

exec function ShowServerFPS(bool show)
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

  // draw box
  x = canvas.ClipX - 55;
  y = 33;
  canvas.DrawColor = BackgroundColor;
  canvas.SetPos(x, y);
  canvas.DrawRect(50, 60);
  
  // draw number
  canvas.DrawColor = owner.TickRate >= 57 ? TextColorGreen : owner.TickRate >= 50 ? TextColorYellow : TextColorRed; 
  canvas.Font = MessageFont;
  canvas.SetPos(x + 5, y + 2);
  canvas.DrawText(string(owner.TickRate), false, 1.0, 1.0);

  // draw "Server FPS"
  canvas.DrawColor = TextColorWhite;
  canvas.SetPos(x + 5, y + 28);
  canvas.DrawText("Server", false, 0.5, 0.5);
  canvas.SetPos(x + 5, y + 45);
  canvas.DrawText("FPS", false, 0.5, 0.5);

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
  TextColorGreen=(R=255,G=255,B=255,A=128)
  TextColorYellow=(R=255,G=200,B=0,A=200)
  TextColorRed=(R=255,G=40,B=40,A=255)
  TextColorWhite=(R=255,G=255,B=255,A=200)
  BackgroundColor=(R=0, G=0, B=0, A=64)
}
