TOXIKK Mutator Pack
===

Installation through [Steam Workshop](http://steamcommunity.com/sharedfiles/filedetails/?id=603855831):   
SteamApps\\workshop\\content\\324810\\603855831

Manual installation (without Steam Workshop):   
SteamApps\\common\\TOXIKK\\UDKGame\\Script\\[MutatH0r.u](http://toxikk.beham.biz/toxikkredirect2/MutatH0r.u)
SteamApps\\common\\TOXIKK\\UDKGame\\Config\\[UDKMutatH0r.ini](http://toxikk.beham.biz/toxikkredirect2/UDKMutatH0r.ini)


The INI file settings are optimized for a server that runs a combination of Vampire + Regen/Decay + Stim Head.

**Included Mutators:**

<a href="#DmgPlume">Damage Plumes</a>
| <a href="#SuperStingray">SuperStingray</a>
| <a href="#Roq3t">Roq3t</a>
| <a href="#RegenDecay">Regen/Decay</a>
| <a href="#Loadout">Loadout</a>
| <a href="#Vampire">Vampire</a>
| <a href="#Piledriver">Piledriver</a>
| <a href="#StimHead">StimHead</a>
| <a href="#PulseHead">PulseHead</a>
| <a href="#ComboGib">ComboGib</a>
| <a href="#InstaBounce">InstaBounce</a>
| <a href="#InstaCcBoost">InstaCC Boost</a>
| <a href="#Gravity">Gravity</a>
| <a href="#TickRate">TickRate</a>
| <a href="#ServerDescription">ServerDescription</a>
| <a href="#SaveShaderCache">SaveShaderCache</a>
<p>


<a name="DmgPlume"/>
Damage Plumes
---
Pops out a number over your target's head whenever you hit it: [YouTube](https://www.youtube.com/watch?v=QYlPOBKEHio)   
The plumes can be configured through UDKMutatH0r.ini, which can hold sections for multiple plume presets like
\[Small DmgPlumeConfig\], ...   
In your console you can select a preset with the command: plumes \<preset-name\>.   
Default presets are: off, small, large.
You can modify them or add new ones as you see fit.


<a name="SuperStingray"/>
SuperStingray
---
Stingray plasma ball is reduced to 17 dmg/hit (from 35) but it has splash damage and knockback.  
This allows you to climb up walls!


<a name="Roq3t"/>
Roq3t
---
Direct rocket hits deal 120 damage, but any splash is reduced to 0.5x regular.  
Knockback is increased to 1.5x and self-damage is disabled.  
All of that can be configured individually in the INI.  


<a name="RegenDecay"/>
Regen/Decay
---
Allows to increase/decrease health and armor over time.  
Typical use cases are health/armor decay (if they are above 100/50) or automatic health regeneration.


<a name="Loadout"/>
Loadout
---
Lets you spawn with certain weapons in your inventory.  
Also has options to set infinite ammo and/or disable regular weapon spawns.


<a name="Vampire"/>
Vampire
---
When you deal damage, 75% of it is given to you as health.


<a name="Piledriver"/>
Piledriver
---
Jump on a player's head to stomp him into the ground.
Jump on him again before he digs himself out to deal 300 damage.


<a name="StimHead"/>
Stim Head
---
Extra health and armor makes you an easier target for head shots.  
Scales a player's head size by (health + armor)/100.


<a name="PulseHead"/>
Pulse Head
---
Pulses a player's head size over time so you can get easier head shots, if you can time it right.


<a name="ComboGib"/>
ComboGib
---
Stingray bounces players with primary or secondary fire and tags them to be killed with the other.  
After 2 seconds or when a player touches the ground he becomes untagged again.  
Players get a green tag when they are hit with the beam. They can then be killed with a plasma ball.  
Players get a yellow tag then when they are hit with 2 balls. They can then be killed with a beam.  
In SquadAssault you can untag your team mates with the shot that would normally kill them.


<a name="InstaBounce"/>
InstaBounce
---
Similar to InstaGib, but with plasma balls instead of a zoom.  
The plasma balls deal no damage, but have a massive knockback. 
Use it like a rocket jump or to bounce your opponents into the air as an easy target.


<a name="InstaCcBoost"/>
InstaCC Boost
---
Useful for CellCapture Instagib. Shoot your team mates to give them some extra speed.


<a name="Gravity"/>
Gravity
---
Allows you to change gravity to any value you like. The value must be configured in MutatH0r.ini


<a name="TickRate"/>
TickRate
---
Servers running this mutator allow clients to see how many ticks/second (=FPS) the server can process.  
This allows players and server admins to detect when the server is underpowered or lagging, when it's not at a steady 60.


<a name="ServerDescription"/>
ServerDescription
---
Utility mutator that allows changing server names as part of the map voting process.


<a name="SaveShaderCache"/>
SaveShaderCache
---
Utility mutator for dedicated servers running custom maps.  
Many custom maps don't contain cached shader data, which causes extremely long map loading times and clients to time out.  
With this mutator the server saves the data, so maps load faster the next time.  
