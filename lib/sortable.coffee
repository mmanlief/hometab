Spine = require("spine/core")
App = require("./index")

class SortableController extends Spine.Controller
	user: null

	elements:
		"#pages_grid"			: "items"
		"#dnd_lock"				: "dndLock"
		"#trash_item"			: "trashItem"
		"#add_page_item"		: "addPageItem"
	
	constructor: ->	
		super
		App.UserEvents.bind("optionsChanged", @setupSortable)

	setupSortable: =>
		pageItems = @items.find("div[class*='page-item']")
		if(@user.options.sort_order != "user")
			@disableSortable(pageItems)
		else
			@enableSortable(pageItems)

	enableSortable: (pageItems) =>
		@makeVisible(@dndLock.parent())
		@dndLock.parent().click =>
			if(@dndLock.hasClass("icon-white"))
				@dndLock.removeClass("icon-white")
				pageItems.unbind("mouseenter", @stopItemRumble)
				pageItems.unbind("mouseleave", @startItemRumble)
				@items.sortable("destroy")
				pageItems.trigger("stopRumble")
			else
				@dndLock.addClass("icon-white")
				pageItems.jrumble(speed: 75)
				pageItems.trigger("startRumble")
				pageItems.mouseenter(@stopItemRumble)
				pageItems.mouseleave(@startItemRumble)
				@items.sortable(@sortableEvents(pageItems))

	disableSortable: (pageItems) =>

		@makeInvisible(@dndLock.parent())
		@items.sortable("destroy")
		pageItems.trigger("stopRumble")
		@dndLock.parent().unbind("click")
		pageItems.unbind("mouseenter", @stopItemRumble)
		pageItems.unbind("mouseleave", @startItemRumble)

	sortableEvents: (pageItems) =>
		{
			start: (event, ui) =>
				@makeVisible(@trashItem)
				@makeInvisible(@addPageItem)
				pageItems.each(@stopItemRumble)
			change: (event, ui) =>
				if(ui.item.hasClass("add-page-item"))
					@items.sortable("cancel")
			update: (event, ui) =>
				#save new page ordering
				setOrder = (pageItem, i) =>
					url = jQuery(pageItem).find("a[class='page-item-tooltip']").attr("data-page-url")
					if(url != undefined)
						page = App.User.findPageByUrl(@user.pages, url)
						page.user_order = i
				setTimeout =>
					setOrder item, i for item, i in @items.find("div[class*='page-item']")
					@user.save()
				, 50
			stop: (event, ui) =>

				@makeInvisible(@trashItem)
				@makeVisible(@addPageItem)
				pageItems.each(@startItemRumble)
		}

	startItemRumble: ->
		_this = jQuery(this)
		_this.trigger("startRumble")

	stopItemRumble: ->
		_this = jQuery(this)
		_this.trigger("stopRumble")

	makeVisible: (e) ->
		e.css("visibility", "visible")
		oldDisplay = e.attr('old-display')
		if(null != oldDisplay)
			e.css('display', oldDisplay)

	makeInvisible: (e) ->
		e.css("visibility", "hidden")
		e.attr("old-display", e.css("display"))
		e.css("display", "none")

module.exports.SortableController = SortableController