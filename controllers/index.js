// index:

module.exports = {
    'GET /asdfg': async (ctx, next) => {
        ctx.render('index.html', {
            title: 'Welcome'
        });
    }
};
