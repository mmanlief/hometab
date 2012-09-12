module.exports = [
	from: "/static/*"
	to: "static/*"
,
	require('spine-adapter/rewrites')
,
	from: "/"
	to: "_show/root"
,
	from: "/root"
	to: "_show/root"
,
	from: "/account"
	to: "_update/account"
	method: "POST"
,
	from: "/logon"
	to: "_update/logon"
	method: "POST"
,
	from: "/account"
	to: "_show/account"
,
	from: "/test"
	to: "_show/test"
,
	from: "*"
	to: "_show/not_found"
]