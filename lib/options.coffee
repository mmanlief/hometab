Spine = require("spine/core")
App = require("./index")

class OptionsController extends Spine.Controller
	user: null

	elements:
		"#sort_order"				: "sortOrder"
		"#remember_search"			: "rememberSearch"

	events:
		"change #sort_order"		: "sortChanged"
		"change #remember_search"	: "searchChanged"

	constructor: ->
		super
		@sortOrder.val(@user.options.sort_order)
		@rememberSearch.attr("checked", @user.options.remember_search)

	sortChanged: =>
		@user.options.sort_order = @sortOrder.val()
		@user.save()
		App.UserEvents.trigger("optionsChanged")

	searchChanged: =>
		@user.options.remember_search = @rememberSearch.is(":checked")
		@user.save()
		App.UserEvents.trigger("optionsChanged")

module.exports.OptionsController = OptionsController