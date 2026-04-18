/// 测试视频数据（使用稳定的公开测试视频）
class VideoItem {
  const VideoItem({
    required this.id,
    required this.url,
    required this.title,
    required this.author,
    this.cover,
    this.aspectRatio = 16 / 9,
  });

  final String id;
  final String url;
  final String title;
  final String author;
  final String? cover;
  final double aspectRatio;
}

const kTestVideos = [
  VideoItem(
    id: 'v1',
    url: 'https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/hls/xgplayer-demo.m3u8',
    title: 'Big Buck Bunny',
    author: 'Blender Foundation',
  ),
  VideoItem(
    id: 'v2',
    url: 'https://stream7.iqilu.com/10339/upload_transcode/202002/09/20200209104902N3v5Vpxuvb.mp4',
    title: 'Elephants Dream',
    author: 'Blender Foundation',
  ),
  VideoItem(
    id: 'v3',
    url: 'https://stream7.iqilu.com/10339/upload_transcode/202002/09/20200209105011F0zPoYzHry.mp4',
    title: 'For Bigger Blazes',
    author: 'Google',
  ),
  VideoItem(
    id: 'v4',
    url: 'https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/hls/xgplayer-demo.m3u8',
    title: 'For Bigger Escapes',
    author: 'Google',
  ),
  VideoItem(
    id: 'v5',
    url: 'https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/mp4/xgplayer-demo-360p.mp4',
    title: 'For Bigger Fun',
    author: 'Google',
  ),
  VideoItem(
    id: 'v6',
    url: 'https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/hls/xgplayer-demo.m3u8',
    title: 'For Bigger Joyrides',
    author: 'Google',
  ),
  VideoItem(
    id: 'v7',
    url: 'https://media.w3.org/2010/05/sintel/trailer.mp4',
    title: 'Subaru Outback',
    author: 'Google',
  ),
  VideoItem(
    id: 'v8',
    url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    title: 'Tears of Steel',
    author: 'Blender Foundation',
  ),
];
