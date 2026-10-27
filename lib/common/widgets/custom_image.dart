import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';

class CustomImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final bool isNotification;
  final String placeholder;
  final bool isHovered;
  final bool refreshWebImage;
  final Color? color;
  const CustomImage({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.isNotification = false,
    this.placeholder = '',
    this.isHovered = false,
    this.refreshWebImage = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = image.trim();
    final parsedUrl = Uri.tryParse(imageUrl);
    final isNetworkImage =
        parsedUrl != null &&
        (parsedUrl.scheme == 'http' || parsedUrl.scheme == 'https') &&
        parsedUrl.host.isNotEmpty;
    final hasUsableImage =
        imageUrl.isNotEmpty &&
        imageUrl.toLowerCase() != 'null' &&
        imageUrl.toLowerCase() != 'undefined';
    final fallbackImage = placeholder.isNotEmpty
        ? placeholder
        : (isNotification
              ? Images.notificationPlaceholder
              : Images.placeholder);
    final webImageUrl =
        '${AppConstants.baseUrl}/image-proxy?url=${Uri.encodeQueryComponent(imageUrl)}${refreshWebImage ? '&v=${imageUrl.hashCode}' : ''}';

    return AnimatedScale(
      scale: isHovered ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: !hasUsableImage
          ? Image.asset(
              fallbackImage,
              height: height,
              width: width,
              fit: fit,
              color: color,
            )
          : !isNetworkImage
          ? Image.asset(
              imageUrl,
              height: height,
              width: width,
              fit: fit,
              color: color,
            )
          : CachedNetworkImage(
              key: ValueKey<String>('network-image-$imageUrl'),
              color: color,
              imageUrl: kIsWeb ? webImageUrl : imageUrl,
              height: height,
              width: width,
              fit: fit,
              placeholder: (context, url) => Image.asset(
                fallbackImage,
                height: height,
                width: width,
                fit: fit,
                color: color,
              ),
              errorWidget: (context, url, error) => Image.asset(
                fallbackImage,
                height: height,
                width: width,
                fit: fit,
                color: color,
              ),
            ),
    );
  }
}
