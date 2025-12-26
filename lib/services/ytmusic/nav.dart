/// Navigation helper class for parsing YTMusic API responses
/// Based on BlackHole's implementation
class NavClass {
  static const content = ['contents', 0];
  static const runText = ['runs', 0, 'text'];
  static const tabContent = ['tabs', 0, 'tabRenderer', 'content'];
  static const singleColumn = ['contents', 'singleColumnBrowseResultsRenderer'];
  static const singleColumnTab = [...singleColumn, ...tabContent];
  static const sectionList = ['sectionListRenderer', 'contents'];
  static const sectionListItem = ['sectionListRenderer', ...content];
  static const musicShelf = ['musicShelfRenderer'];
  static const musicShelfContents = [...musicShelf, 'contents'];
  static const navigationBrowse = ['navigationEndpoint', 'browseEndpoint'];
  static const navigationBrowseId = [...navigationBrowse, 'browseId'];
  static const navigationVideoId = [
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ];
  static const navigationPlaylistId = [
    'navigationEndpoint',
    'watchEndpoint',
    'playlistId',
  ];
  static const headerDetail = ['header', 'musicDetailHeaderRenderer'];
  static const headerCardShelf = [
    'header',
    'musicCardShelfHeaderBasicRenderer',
  ];
  static const immersiveHeaderDetail = [
    'header',
    'musicImmersiveHeaderRenderer',
  ];
  static const title = ['title', 'runs', 0];
  static const titleText = ['title', ...runText];
  static const titleRuns = ['title', 'runs'];
  static const titleRun = [...titleRuns, 0];
  static const textRuns = ['text', 'runs'];
  static const textRun = [...textRuns, 0];
  static const textRunText = [...textRun, 'text'];
  static const subtitleRuns = ['subtitle', 'runs'];
  static const secondSubtitleRuns = ['secondSubtitle', 'runs'];
  static const thumbnail = ['thumbnail', 'thumbnails'];
  static const thumbnails = [
    'thumbnail',
    'musicThumbnailRenderer',
    ...thumbnail,
  ];
  static const thumbnailCropped = [
    'thumbnail',
    'croppedSquareThumbnailRenderer',
    ...thumbnail,
  ];
  static const mRLIR = 'musicResponsiveListItemRenderer';
  static const mRLIRFlex = ['musicResponsiveListItemRenderer', 'flexColumns'];
  static const mRLIFCR = 'musicResponsiveListItemFlexColumnRenderer';
  static const mrlirPlaylistId = [mRLIR, 'playlistItemData', 'videoId'];
  static const mrlirBrowseId = [mRLIR, ...navigationBrowseId];

  /// Navigate through nested map/list structure
  static dynamic nav(dynamic root, List items) {
    try {
      dynamic res = root;
      for (final item in items) {
        res = res[item];
      }
      return res;
    } catch (e) {
      return null;
    }
  }

  /// Join text from runs array
  static String joinRunTexts(List? runs) {
    if (runs == null) return '';
    return runs.map((e) => e['text']).toList().join();
  }

  /// Extract URLs from runs array
  static List runUrls(List? runs) {
    if (runs == null) return [];
    return runs.map((e) => e['url']).toList();
  }
}
