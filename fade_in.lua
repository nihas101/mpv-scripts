local msg = require('mp.msg')

local ov = mp.create_osd_overlay('ass-events')
local state = {
	time_step_sec = 0.1,
	init_volume = 25,
	volume_step = 2,
	expected_volume = 0,
	target_volume = 100,
	timer = nil,
}

function update_ov(percent_amount)
	ov.data = '{\\pos(10, 10)\\{\\fs10}{\\an7}{\\bord2}' .. percent_amount ..'%'
	ov:update()
	ov.data = nil
end

function finish_fade_in()
	if state.timer then
		msg.debug('Ending the timer')
		state.timer:kill()
	else
		msg.warn('No timer available')
	end
	ov:remove()
end

function fade_in_volume()
	-- Check if the user interrupted the fadein
	-- In that case we abort, because the user likely adjusted the volume for a reason
	local current_volume = tonumber(mp.get_property('volume'))
	if state.expected_volume ~= current_volume then
		msg.info('Fade in interrupted by user input')
		finish_fade_in()
		return
	end

	-- Increase volume to the next step
	local next_volume = current_volume + state.volume_step 
	if next_volume < state.target_volume then
		msg.debug('Increasing volume to ' .. next_volume)
		mp.set_property('volume',  next_volume)
		state.expected_volume = next_volume
		update_ov(next_volume)
	else
		mp.set_property('volume',  state.target_volume)
		finish_fade_in()
		msg.debug('Previous max volume (' .. state.target_volume .. ') reached ')
	end
end

function init_fade_in(event)
	state.target_volume = tonumber(mp.get_property('volume')) -- We set this again here in case the user adjusted the volume before playing a video
	msg.info('Fading volume from ' .. state.init_volume .. ' to ' .. state.target_volume)
	mp.set_property('volume',  state.init_volume)
	state.expected_volume = state.init_volume
	state.timer = mp.add_periodic_timer(state.time_step_sec, fade_in_volume)
end

function restore_volume()
	-- If the user or mpv exits early we restore the volume to the old state properly
	finish_fade_in()
	mp.set_property('volume',  state.target_volume)
end

state.target_volume = tonumber(mp.get_property('volume'))
msg.debug('shutdown event registerd: ' .. tostring(mp.register_event('shutdown', restore_volume)))
msg.debug('file-loaded event registered: ' .. tostring(mp.register_event('file-loaded', init_fade_in)))