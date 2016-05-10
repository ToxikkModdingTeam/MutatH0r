class TickRateInteraction extends Interaction;

// defined at initialization
var PlayerController PC;
var CRZMutator_TickRate Owner;

// static
var Font MessageFont;
var Color TextColor;
var Color BackgroundColor;

// instance
var bool Visible;

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

exec function TickRate()
{
  Visible = !Visible;
}

event PostRender(Canvas canvas)
{
  local CRZHudWrapper wrapper;

  super.PostRender(canvas);

  if (Owner == None) // actor destroyed when match is over
    return;

  wrapper = CRZHudWrapper(PC.myHUD);
  if (wrapper == None)
    return;
  
  if (wrapper.CurrentHudMode == HM_Intro)
    return;

  if (Visible)
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
  canvas.DrawRect(50, 30);
  
  // draw header + message
  canvas.DrawColor = TextColor; 
  canvas.Font = MessageFont;
  canvas.SetPos(x + 5, y + 2);
  canvas.DrawText(string(owner.TickRate), false, 1.0, 1.0);
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
  TextColor=(R=255,G=255,B=255,A=255)
  BackgroundColor=(R=0, G=0, B=0, A=128)
  Visible = true
}
