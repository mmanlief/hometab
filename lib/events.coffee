duality_events = require('duality/events')
session = require('session')
utils = require('duality/utils')

logon = () ->
	setError = (err) ->
		jQuery("#logon_error").text(err.toString())

	checkInput = (input) ->
		return input? && input != undefined && input != ""

	username = $("#id_logonusername").val()
	password = $("#id_logonpassword").val()
	if(!checkInput(username))
		return setError("Please enter a username")
	if(!checkInput(password))
		return setError("Please enter a password")
	session.login(username, password, (err) =>
		if(null != err)
			setError(err)
		else
			setTimeout(->
				window.location.href = "/root"
			, 100)
	)

bindElement = (el, func) ->
	if(!(el.attr('eventsBound')?))
		func(el)
		el.attr('eventsBound', 'true')

bindLogonForm = () ->
	bindElement(jQuery("#logon_form button"), (btn) ->
		btn.click((ev) ->
			ev.preventDefault()
			logon()
			return false
		)
	)
	bindElement(jQuery("#logon_form input"), (input) ->
		input.keypress((ev) ->
			if(ev.which == 13)
				ev.preventDefault()
				logon()
				return false;
		)
	)

bindLogoutLink = () ->
	bindElement(jQuery("#logoff_link"), (link) ->
		link.click((ev) ->
			ev.preventDefault()
			session.logout((err, response) ->
				if(!err?)
					window.location.href = "/account"
			)
		)
	)

bindEvents = (names, ev) ->
	names.forEach((name) ->
		duality_events.on(name, ev)
	)

initEvents = ['afterResponse', 'init']

bindEvents(initEvents, bindLogonForm)
bindEvents(initEvents, bindLogoutLink)