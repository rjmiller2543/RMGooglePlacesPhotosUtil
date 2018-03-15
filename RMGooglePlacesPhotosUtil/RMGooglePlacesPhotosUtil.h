//
//  RMGooglePlacesPhotosUtil.h
//  Pods-RMGooglePlacesPhotosUtil_Example
//
//  Created by RMiller on 3/14/18.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

typedef void(^RMPhotoCallback)(NSError *error, UIImage *image);
typedef void(^RMURLCallback)(NSError *error, NSURL *url);

@interface RMGooglePlacesPhotosUtil : NSObject

typedef NS_ENUM(NSInteger, RMPhotoError) {
    RMPhotoErrorInvalidLocation,
    RMPhotoErrorInvalidType,
    RMPhotoErrorInvalidName,
    RMPhotoErrorInvalidImage,
    RMPhotoErrorNoCallback
};

/* The preferred method is to init with API Key - you can get an API Key from the Google Maps API Developer Site https://developers.google.com/maps/documentation/geocoding/get-api-key */
-(instancetype)initWithApiKey:(NSString *)apiKey;

/* Keeping the Utility flexible for those who want to init then set the key */
-(void)setApiKey:(NSString *)apiKey;

/* Method to get the image of the closest matching place and the first photo in the array of photos */
-(void)getImageWithLocation:(CLLocationCoordinate2D)location type:(NSString *)type name:(NSString *)name callback:(RMPhotoCallback)callback;

/* Method to get just the url for the closest matching place and the first photo in the array of photos for use in SDWebImage, AF, or some other URL Based Cacheing */
-(void)getImageURLWithLocation:(CLLocationCoordinate2D)location type:(NSString *)type name:(NSString *)name callback:(RMURLCallback)callback;

@end

