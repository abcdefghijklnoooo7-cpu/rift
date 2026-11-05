local B={}
function B.Pattern(w,index)
 local growth=math.min(index/7,1)
 local horizontal=math.sin(index*.72+(w.finish or 0))*math.min(index/10,1)*.32
 return w.pitchKick*(.42+.38*growth),horizontal*w.pitchKick
end
function B.Error(w,moving,airborne,ads,index)
 if w.item then return 0 end
 local base=ads and w.ads or w.hip
 local precision=w.family=='sniper' or w.family=='marksman'
 -- A settled, grounded ADS opening shot follows the exact crosshair ray.
 if index==1 and not airborne and (ads or (moving<.08 and not precision)) then return 0 end
 return base*(.18+math.min(index/14,.7)) + moving*(ads and .25 or (precision and 1.25 or .65))+(airborne and 2 or 0)
end
-- Configuration range is the effective damage range, not a point at which bullets disappear.
function B.TraceRange(w)
 return w.blastRadius and w.range or math.max(w.range,1200)
end
function B.Falloff(w,distance)
 if w.blastRadius then return 1 end
 if w.pellets then return math.clamp(1.2-distance/w.range,.15,1) end
 if distance<=w.range then return 1 end
 return math.clamp(1-(distance-w.range)/math.max(w.range,1)*.45,.35,1)
end
return B
