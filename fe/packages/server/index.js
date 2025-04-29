import express from 'express'
import cors from 'cors'
import axios from 'axios'

const app = express()

// 使用cors中间件来允许所有跨域请求
// 注意：在实际生产环境中，你应该更具体地配置CORS策略
app.use(cors())
app.use(express.json())

app.post('/proxy', async (req, res) => {
	try {
		const { url, data, header, timeout, method, responseType } = req.body
		// 构建请求配置
		const axiosConfig = {
			method: method.toUpperCase(),
			url,
			timeout,
			headers: header,
			data,
			responseType,
		}
		// 发送请求到目标服务
		const response = await axios(axiosConfig)
		// 转发响应给客户端
		if (responseType === 'arraybuffer') {
			// 对于 arraybuffer 响应，直接用 res.send 发送二进制数据
			res.status(response.status).send(response.data)
		}
		else {
			res.status(response.status).json(response.data)
		}
	}
	catch (error) {
		// 处理错误并返回给客户端
		console.error('Error forwarding request:', error.message)
		res.status(error.response ? error.response.status : 500).json({ error: error.message })
	}
})

app.listen(7788, () => {
	console.log('Server is running on port 7788')
})
