class MotdInteraction extends Interaction;

// defined at initialization
var PlayerController PC;
var CRZMutator_Motd Owner;

// static
var Font HeaderFont, MessageFont;
var Color TextColor;
var Color BackgroundColor;
var EHudMode PrevHudMode;

// instance
var bool Visible;

static function MotdInteraction Create(CRZMutator_Motd theOwner, PlayerController controller, optional bool bReturnExisting=true)
{
  local MotdInteraction newInt;
  local int i;
 
  if (bReturnExisting)
  {
    for (i=0; i<controller.Interactions.length; i++)
    {
      if (controller.Interactions[i].class == default.class)
        return MotdInteraction(controller.Interactions[i]);
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

exec function Motd()
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
  
  // show MOTD during PreMatchLobby (after intro, before game)
  if (wrapper.CurrentHudMode != PrevHudMode)
  {
    if (wrapper.CurrentHudMode == HM_PreMatchLobby && PrevHudMode == HM_Intro)
      Visible = true;
    else if (PrevHudMode == HM_PreMatchLobby)
      Visible = false;
    PrevHudMode = wrapper.CurrentHudMode;
  }

  if (Visible)
    RenderMotd(canvas);
}

function RenderMotd(Canvas canvas)
{
  local float x,y,w,h,width, height, messageY;
  local int i, c;
  local int padding;
  local string line;

  padding = 10;

  // calc header height / width
  canvas.Font = HeaderFont;
  canvas.TextSize(owner.ServerWelcomeHeader, width, height, 1.0, 1.0); 
  messageY = height;

  // calc message height / width
  c = ArrayCount(owner.ServerWelcomeMessageLines);
  canvas.Font = MessageFont;
  for (i=0; i<c; i++)
  {
    line = owner.ServerWelcomeMessageLines[i];
    if (line == class'CRZMutator_Motd'.const.EndMarker)
      break;
    if (line == "") line = "Äj";
    canvas.TextSize(line, w, h, 1.0, 1.0);
    width = FMax(width, w);
    height += h;
  }

  // draw box
  x = (canvas.ClipX - width) / 2;
  y = 150;
  canvas.DrawColor = BackgroundColor;
  canvas.SetPos(x - padding, y - padding);
  canvas.DrawRect(width + 2*padding, height + 2*padding);
  
  // draw header + message
  canvas.DrawColor = TextColor; 
  canvas.Font = HeaderFont;
  canvas.SetPos(x, y);
  canvas.DrawText(owner.ServerWelcomeHeader, false, 1.0, 1.0);
  canvas.Font = MessageFont;
  canvas.SetPos(x, y + messageY);
  canvas.DrawText(owner.ServerWelcomeMessageString, false, 1.0, 1.0);
}

event NotifyGameSessionEnded()
{
  super.NotifyGameSessionEnded();
  Owner = None;
  PC = None;
}

DefaultProperties
{
  HeaderFont=Font'UI_Fonts.Fonts.UI_Fonts_Positec36'
  MessageFont=Font'UI_Fonts.Fonts.UI_Fonts_Positec18'
  TextColor=(R=255,G=255,B=255,A=255)
  BackgroundColor=(R=0, G=0, B=0, A=128)
  PrevHudMode = HM_None
}
