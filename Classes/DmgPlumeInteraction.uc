class DmgPlumeInteraction extends Interaction;

// defined at initialization
var GameViewportClient Viewport;
var PlayerController PC;
var DmgPlumeActor Owner;

// static
var Font PlumeFont;
var Font CrosshairNameFont;
var Color CrosshairNameColor;


static function DmgPlumeInteraction Create(DmgPlumeActor theOwner, PlayerController controller, optional bool bReturnExisting=true)
{
  local DmgPlumeInteraction newInt;
  local int i;
 
  if (bReturnExisting)
  {
    for (i=0; i<controller.Interactions.length; i++)
    {
      if (controller.Interactions[i].class == default.class)
        return DmgPlumeInteraction(controller.Interactions[i]);
    }
  }
 
  newInt = new(LocalPlayer(controller.Player).ViewportClient) default.class;
  LocalPlayer(controller.Player).ViewportClient.InsertInteraction(newInt, 0);
  controller.Interactions.InsertItem(0, newInt);
  newInt.Owner = theOwner;
  return newInt;
}
 
function Initialized()
{
  Viewport = GameViewportClient(Outer);
  PC = Viewport.GetPlayerOwner(0).Actor;
}
 
exec function Plumes(optional string preset)
{
  local array<string> names;
  local string msg, iniPreset;
  local int i;

  preset = Locs(preset);
  if (preset == "")
  {
    if (!GetPerObjectConfigSections(class'DmgPlumeConfig', names)) // names are returned in reverse order
    {
      names.AddItem("large");
      names.AddItem("small");
      names.AddItem("off");
    }
    for (i=names.Length-1; i>=0; i--)
    {
      if (msg != "") msg = msg $ ", ";
      iniPreset = repl(locs(names[i]), " dmgplumeconfig", "");
      msg = msg $ "<font color=\"" $ (iniPreset == Owner.DmgPlumeConfig ? "#ffff00" : "#00ffff") $ "\">" $ iniPreset $ "</font>";
    }
    PC.ClientMessage("Usage: <font color=\"#ffff00\">plumes </font>&lt;<font color=\"#00ffff\">preset</font>&gt; with one of these presets: " $ msg);
  }
  else if (!Owner.LoadPreset(preset))
  {
    PC.ClientMessage("Plumes: unknown preset: " $ preset);
  }    
}

exec function CrosshairNames(bool show)
{
  if (Owner != None)
    Owner.Settings.bEnableCrosshairNames = show;
}

event PostRender(Canvas canvas)
{
  if (Owner == None) // actor destroyed when match is over
    return;

  if (Owner.Settings.bEnablePlumes)
    RenderDamagePlumes(canvas);
  if (Owner.Settings.bEnableCrosshairNames)
    RenderCrosshairName(canvas);
}

function RenderDamagePlumes(Canvas canvas)
{
  local int i;
  local vector pos;
  local Vector2D textSize;
  local PlumeSpriteInfo plume;
  local int alpha;
  local float sizeScale;
  local float distance;
  local float gravity;

  gravity = Owner.Settings.SpeedY.Fixed + Owner.Settings.SpeedY.Random / 2;

  for (i=0; i<Owner.Plumes.Length; i++)
  {
    plume = Owner.Plumes[i];
    pos = canvas.Project(plume.Location);
    pos.X += plume.SpeedX * plume.Age;
    pos.Y += -plume.SpeedY * plume.Age + gravity * plume.Age * plume.Age;

    if (pos.X < 0 || pos.X >= canvas.ClipX || pos.Y < 0 || pos.Y >= canvas.ClipY)
      continue;

    distance = PC.Pawn == None ? 1000.0 : VSize(PC.Pawn.Location - plume.Location);
    if (distance < 0)
      sizeScale = Owner.Settings.ScaleLarge;
    else if (distance > Owner.Settings.ScaleDistance)
      sizeScale = Owner.Settings.ScaleSmall;
    else
      sizeScale = (1-(distance/Owner.Settings.ScaleDistance)) * (Owner.Settings.ScaleLarge - Owner.Settings.ScaleSmall) + Owner.Settings.ScaleSmall;
   
    canvas.Font = PlumeFont;
    canvas.TextSize(string(plume.Value), textSize.X, textSize.Y, sizeScale, sizeScale);
    if (pos.X + textSize.X / 2 + 1 >= canvas.ClipX)
      continue;

    alpha = int(255.0 * fclamp(1.0 - (plume.Age-0.5)/Owner.Settings.TimeToLive, 0, 1));

    canvas.DrawColor = GetColor(plume);
    canvas.DrawColor.A = alpha;
    canvas.SetPos(pos.X - textSize.X/2, pos.Y - textSize.Y/2);
    canvas.DrawText(string(plume.Value), false, sizeScale, sizeScale);
  }
}

function RenderCrosshairName(Canvas canvas)
{
  local CRZPawn target;
  local Vector start, end, hitLocation, hitNormal;
  local Rotator rot;
  local float width, height;

  if (PC.Pawn == None)
    return;
  
  PC.GetPlayerViewPoint(start, rot);
  end = start + vector(rot) * 10000;
  target = CRZPawn(PC.Pawn.Trace(hitLocation, hitNormal, end, start));
  if (target != None && target.PlayerReplicationInfo != None && target.CurrentStealthFactor <= 0.5)
  {
    canvas.Font = CrosshairNameFont;
    canvas.TextSize(target.PlayerReplicationInfo.PlayerName, width, height, 1.0, 1.0);
    canvas.SetPos(canvas.ClipX / 2 - width / 2, canvas.ClipY * 4 / 10 - height / 2);
    canvas.DrawColor = CrosshairNameColor;
    canvas.DrawText(target.PlayerReplicationInfo.PlayerName, false, 1.0, 1.0);
  }
}

simulated function Color GetColor(PlumeSpriteInfo plume)
{
  local PlumeColor prevCol, col;
  local int i,c;

  c = Owner.Settings.PlumeColors.Length;
  prevCol = Owner.Settings.PlumeColors[0];
  for (i=1; i<c; i++)
  {
    col = Owner.Settings.PlumeColors[i];
    if (plume.Value < col.Damage)
      return prevCol.Color;
    prevCol = col;
  }
  return col.Color;
}

event NotifyGameSessionEnded()
{
  Owner = None;
  PC = None;
  Viewport = None;

  super.NotifyGameSessionEnded();
}

DefaultProperties
{
  PlumeFont=Font'KismetGame_Assets.Fonts.JazzFont_05'
  CrosshairNameFont=Font'UI_Fonts.Fonts.UI_Fonts_Positec18'
  CrosshairNameColor=(R=255,G=255,B=255,A=255)
}
