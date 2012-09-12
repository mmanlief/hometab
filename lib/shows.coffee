templates = require("duality/templates")
forms = require("./forms")
utils = require('duality/utils')

redirect = (location) ->
	return {
		body: "Please update your browser.",
		code: 302,
		headers: {
			location: location
		}
	}

exports.root = (doc, req) ->
	if(req.userCtx.name == null)
		return redirect('account')
	else
		return {
			title: "HomeTab",
			content: templates.render("home.html", req, {}),
			loggedIn: true
		}

exports.account = (doc, req) ->
	if(req.userCtx.name != null)
		return redirect('root')
	else
	    return { 
		    title: 'Create account',
		    content: templates.render('account.html', req, {
		    	registerForm: forms.account.toHTML(req)
		    	next: req.query.next
		    })
	    }

exports.test = (doc, req) ->
	title: "Test",
	content: req.userCtx.name + "<br />" + JSON.stringify(req)