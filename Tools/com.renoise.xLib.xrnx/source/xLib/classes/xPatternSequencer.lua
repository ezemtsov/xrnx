--[[===============================================================================================
xPatternSequencer
===============================================================================================]]--

--[[--

Static methods for working with the renoise.PatternSequence
.
#

]]

class 'xPatternSequencer' 

---------------------------------------------------------------------------------------------------
-- [Static] Check if position is within actual song boundaries
-- @param seq_idx, int
-- @return bool

function xPatternSequencer.within_bounds(seq_idx)
  TRACE("xPatternSequencer.within_bounds(seq_idx)",seq_idx)

  if (seq_idx > #rns.sequencer.pattern_sequence) then
    return false
  elseif (seq_idx < 1) then
    return false
  else
    return true
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Enable loop for the section that playback is currently located in

function xPatternSequencer.loop_current_section()
  local seq_pos = rns.transport.edit_pos.sequence
  local section_index = xPatternSequencer.get_section_index_by_seq_pos(seq_pos)
  xPatternSequencer.loop_section_by_index(section_index)
end

---------------------------------------------------------------------------------------------------
-- [Static] Loop the specified section 
-- @param section_index (number)

function xPatternSequencer.loop_section_by_index(section_index)

  local positions = xPatternSequencer.gather_section_positions()
  if table.is_empty(positions) then
    return
  end
  if not positions[section_index] then
    return
  end

  -- rules: enable loop if partially selected, or unselected
  -- disable loop if section (and _only_ section) is wholly looped

  local section_start = positions[section_index] 
  local section_end = positions[section_index+1] and 
    positions[section_index+1]-1 or #rns.sequencer.pattern_sequence

  local within_range = function(pos,range_start,range_end)
    return pos >= range_start and pos <= range_end
  end

  local enable_loop = false
  local loop_seq_empty = (rns.transport.loop_sequence_range[1] == 0) and 
    (rns.transport.loop_sequence_range[2] == 0)
  if not loop_seq_empty then
    local all_looped,all_empty = false,false
    for k,v in ipairs(rns.sequencer.pattern_sequence) do
      if within_range(k,section_start,section_end) then
        if within_range(k,rns.transport.loop_sequence_start,rns.transport.loop_sequence_end) then
          if not all_looped then
            all_looped = true
          end
          all_empty = false
        else
          if not all_empty then
            all_empty = true
          end
          all_looped = false
        end
      end
    end
    if all_looped then
      enable_loop = false
    elseif all_empty then
      enable_loop = true
    end
  else
    enable_loop = true
  end

  if enable_loop then
    rns.transport.loop_sequence_range = {section_start,section_end}
  else
    rns.transport.loop_sequence_range = {}
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Retrieve indices for sections in pattern-sequence

function xPatternSequencer.gather_section_positions()
  local positions = {}
  for k,v in ipairs(rns.sequencer.pattern_sequence) do
    if rns.sequencer:sequence_is_start_of_section(k) then
      table.insert(positions,k)
    end
  end
  return positions
end

---------------------------------------------------------------------------------------------------
-- [Static] Retrieve section-index for a given position in the pattern-sequence
-- @param seq_pos (number)

function xPatternSequencer.get_section_index_by_seq_pos(seq_pos)
  local positions = xPatternSequencer.gather_section_positions()
  if not table.is_empty(positions) then
    for k,v in ipairs(positions) do
      if (v > seq_pos) then
        return k-1
      elseif (v == seq_pos) then
        return k
      end
    end
    return #positions,positions
  end
  
end

---------------------------------------------------------------------------------------------------
-- [Static] Schedule a given section-index for playback 
-- @param section_index

function xPatternSequencer.set_scheduled_section(section_index)
  local positions = gather_section_positions()
  if positions[section_index] then
    rns.transport:set_scheduled_sequence(positions[section_index])
  end
end

---------------------------------------------------------------------------------------------------
-- [Static] Get_playing_pattern
-- @return renoise.Pattern 

function xPatternSequencer.get_playing_pattern()
  local idx = rns.transport.playback_pos.sequence
  return rns.patterns[rns.sequencer.pattern_sequence[idx]]
end

---------------------------------------------------------------------------------------------------
-- [Static] Retrieve the pattern index 
-- OPTIMIZE how to implement a caching mechanism? 
-- @param seq_idx, sequence index 
-- @return int or nil 

function xPatternSequencer.get_number_of_lines(seq_idx)
  TRACE("xPatternSequencer.get_number_of_lines(seq_idx)",seq_idx)
	
  assert(type(seq_idx) == "number")

  local patt_idx = rns.sequencer:pattern(seq_idx)
  if patt_idx then
    return rns:pattern(patt_idx).number_of_lines
  end

end

