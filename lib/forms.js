var fields = require('couchtypes/fields'),
    Form = require('couchtypes/forms').Form,
    widgets = require('./register');


exports.account = new Form({
    username: fields.string({
        widget: widgets.username()
    }),
    email: fields.email({
    	widget : widgets.email()
    }),
    password: fields.password()
});