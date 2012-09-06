templates = require("duality/templates")

exports.root = (doc, req) ->
	if(!(req.user?))
		return {
			body: "Please update your browser.",
			code: 302,
			headers: {
				location: "create_account"
			}
		}
	else
		return {
			title: "HomeTab",
			content: templates.render("home.html", req, {})
		}

exports.create_account = (doc, req) ->
    return { 
	    title: 'Create account',
	    content: templates.render('create_account.html', req, {
	    	form: require('./forms').create_user.toHTML(req),
	    	next: req.query.next
	    })
    }