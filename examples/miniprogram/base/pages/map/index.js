Page({
  data: {
    longitude: 116.397428,
    latitude: 39.90923,
    scale: 14,
    showLocation: false,
    status: '地图加载中',
    markers: [
      { id: 0, longitude: 116.397428, latitude: 39.90923, title: '地点 A', callout: { content: '地点 A', display: 'BYCLICK' } },
      { id: 1, longitude: 116.407428, latitude: 39.91923, title: '地点 B' },
    ],
  },
  onReady() { this.map = wx.createMapContext('places') },
  onMapReady() { this.setData({ status: '地图已就绪' }) },
  onMapError(event) { this.setData({ status: event.detail.errMsg }) },
  onMarkerTap(event) { this.setData({ status: `点击标记 ${event.detail.markerId}` }) },
  onRegionChange(event) {
    if (event.detail.type === 'end') this.setData({ status: `当前缩放 ${event.detail.scale}` })
  },
  showAll() {
    this.map.includePoints({ points: this.data.markers, padding: [32, 32, 32, 32], fail: error => this.setData({ status: error.errMsg }) })
  },
  readCenter() {
    this.map.getCenterLocation({
      success: location => this.setData({ status: `${location.longitude}, ${location.latitude}` }),
      fail: error => this.setData({ status: error.errMsg }),
    })
  },
  moveToLocation() {
    this.map.moveToLocation({
      success: () => this.setData({ showLocation: true }),
      fail: error => this.setData({ status: error.errMsg }),
    })
  },
})
