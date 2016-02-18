class DmgPlumeInteraction extends Interaction;

// defined at initialization
var GameViewportClient Viewport;
var PlayerController PC;
var DmgPlumeActor Owner;

// static
var Font TextFont;


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
}
  
event PostRender(Canvas canvas)
{
  local int i;
  local vector pos;
  local Vector2D textSize;
  local PlumeSpriteInfo plume;
  local int alpha;
  local float sizeScale;
  local float distance;
  local float gravity;
  
  gravity = class'CRZMutator_DmgPlume'.default.SpeedY.Fixed + class'CRZMutator_DmgPlume'.default.SpeedY.Random / 2;

  for (i=0; i<Owner.Plumes.Length; i++)
  {
    plume = Owner.Plumes[i];
    pos = canvas.Project(plume.Location);
    pos.X += plume.SpeedX * plume.Age;
    pos.Y += -plume.SpeedY * plume.Age + gravity * plume.Age * plume.Age;

    if (pos.X < 0 || pos.X >= canvas.ClipX || pos.Y < 0 || pos.Y >= canvas.ClipY)
      continue;

    distance = VSize(Owner.GetALocalPlayerController().Pawn.Location - plume.Location);
    if (distance < 0)
      sizeScale = class'CRZMutator_DmgPlume'.default.ScaleLarge;
    else if (distance > class'CRZMutator_DmgPlume'.default.ScaleDistance)
      sizeScale = class'CRZMutator_DmgPlume'.default.ScaleSmall;
    else
      sizeScale = (1-(distance/class'CRZMutator_DmgPlume'.default.ScaleDistance)) * (class'CRZMutator_DmgPlume'.default.ScaleLarge - class'CRZMutator_DmgPlume'.default.ScaleSmall) + class'CRZMutator_DmgPlume'.default.ScaleSmall;
   
    canvas.Font = TextFont;
    canvas.TextSize(string(plume.Value), textSize.X, textSize.Y, sizeScale, sizeScale);
    if (pos.X + textSize.X / 2 + 1 >= canvas.ClipX)
      continue;

    alpha = int(255.0 * fclamp(1.0 - (plume.Age-0.5)/class'CRZMutator_DmgPlume'.default.TimeToLive, 0, 1));

    canvas.DrawColor = GetColor(plume);
    canvas.DrawColor.A = alpha;
    canvas.SetPos(pos.X - textSize.X/2, pos.Y - textSize.Y/2);
    canvas.DrawText(string(plume.Value), false, sizeScale, sizeScale);
  }
}

simulated function Color GetColor(PlumeSpriteInfo plume)
{
  local PlumeColor prevCol, col;
  local int i,c;

  c = class'CRZMutator_DmgPlume'.default.PlumeColors.Length;
  prevCol = class'CRZMutator_DmgPlume'.default.PlumeColors[0];
  for (i=1; i<c; i++)
  {
    col = class'CRZMutator_DmgPlume'.default.PlumeColors[i];
    if (plume.Value < col.Damage)
      return prevCol.Color;
    prevCol = col;
  }
  return col.Color;
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
  TextFont=Font'KismetGame_Assets.Fonts.JazzFont_05'
}
