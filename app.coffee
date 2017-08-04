express = require('express')
http = require('http')
serve_static = require('serve-static')
path = require('path')

bodyParser = require('body-parser')
cookieParser = require('cookie-parser')
expressSession = require('express-session')

#  에러 핸들러 모듈 사용
expressErrorHandler = require('express-error-handler')

# mongodb 모듈 사용
MongoClient = require('mongodb').MongoClient

database =

connectDB ->
  databaseUrl = 'mongodb://localhost:27017/local'

  MongoClient.connect(databaseURL, (err, db) ->
    if (err)
      console.log('데이터베이스 연결 시 에러 발생함.')
    console.log('데이터베이스에 연결됨 : ' + databaseUrl)
    database = db
  )
app = express()

app.set('port', process.env.PORT || 3000)
app.use('/public', serve_static(path.join(__dirname, 'public')))


app.use(bodyParser.urlencoded({extended:false}))
app.use(bodyParser.json())

app.use(cookieParser())
app.use(expressSession(
  secret:'my key',
  resave:true,
  saveUninitialized:true
))



router = express.Router()

router.route('/process/login').post((rea, res) ->
  console.log('/process/login 라우팅 함수 호출됨.')

  paramId = req.body.id || req.query.id
  paramPassword = req.body.password || req.query.password
  console.log('요청 파라미터 : ' + paramId + ', ' + paramPassword)

  if(database)
    authUser(database, paramId, paramPassword, (err, docs) ->
      if(err)
        console.log('에러 발생.')
        res.writeHead(200, {"Content-Type" : "text/html;charset=utf8"})
        res.write('<h1>에러 발생</h1>')
        res.end()

      if(docs)
        console.dir(docs)

        res.writeHead(200, {"Content-Type":"text/html;charset=utf8"})
        res.write('<h1>사용자 로그인 성공</h1>')
        res.write('<div><p>사용자 : ' + docs[0].name + '</p></div>')
        res.write('<br><br><a href="/public/login.html">다시 로그인하기</a>')
        res.end()
    )
   else
    console.log('에러 발생.')
    res.writeHead(200, {"Content-Type" : "text/html;charset=utf8"})
    res.write('<h1>에러 발생</h1>')
    res.end()


)

app.use('/', router)

authUser = (db, id, password, callback) ->
  console.log('authUser 호출됨.')

  users = db.collection('users')

  users.find({"id":id, "password":password}).toArray((err, docs) ->
    if(err)
      callback(err, null)
    if(docs.length > 0)
      console.log('일치하는 사용자를 찾음')
      callback(null, docs)
    else
      console.log('일치하는 사용자를 찾지 못함.')
      callback(null, null)
  )
  # 404 에러 페이지 처리
errorHandler = expressErrorHandler({
  serve_static: {
    '404': '.public/404.html'
  }
})

app.use(expressErrorHandler.httpError(404))
app.use(errorHandler)



server = http.createServer(app).listen(app.get('port'), ->
  console.log('익스프레스로 웹 서버를 실행함 : ' + app.get('port'))

  connectDB()
)