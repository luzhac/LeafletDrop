// sign in:

var mysql = require('mysql');

var con = mysql.createConnection({
  host: "localhost",
  user: "yourusername",
  password: "yourpassword"
});
//导入数据到小程序服务器，显示数据，点击了就更新最近的名单 
//新建数据库用户名密码和导入库
module.exports = {
    'POST /p1': async (ctx, next) => {
        var
            a = ctx.request.body.a ;
            b = ctx.request.body.b || '';
            console.log('signin ok!');
            console.log(a);
            console.log(ctx.request.body.c);
            if (ctx.request.body.c)
            {
              console.log("--"+typeof(a));
              console.log("--"+typeof(JSON.parse(a)));
              for (var x of JSON.parse(a)) {
                console.log("--");
                  console.log(x); // 'A', 'B', 'C'
              }    }
            else
            {
              ctx.render('p1.html', {
                  a: a,
                  b:b
              });
            }


    }
};
