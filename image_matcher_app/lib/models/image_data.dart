class ImageData {
  final String fileName;
  final String correctName;
  final int hashValue;

  ImageData({
    required this.fileName,
    required this.correctName,
    required this.hashValue,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'correctName': correctName,
    'hashValue': hashValue,
  };

  factory ImageData.fromJson(Map<String, dynamic> json) => ImageData(
    fileName: json['fileName'],
    correctName: json['correctName'],
    hashValue: json['hashValue'],
  );
}
