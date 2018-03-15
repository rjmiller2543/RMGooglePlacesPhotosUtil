//
//  RMGooglePlacesPhotosUtil.m
//  Pods-RMGooglePlacesPhotosUtil_Example
//
//  Created by RMiller on 3/14/18.
//

#import "RMGooglePlacesPhotosUtil.h"

@interface RMGooglePlacesPhotosUtil()

@property(nonatomic,copy) NSString *apiKey;

@end

typedef void(^RequestDataCallback)(NSData *data);

@implementation RMGooglePlacesPhotosUtil

#pragma mark - Prototype Methods
//Create the Utility using the Google API Key which will be used to access the API
- (instancetype)initWithApiKey:(NSString *)apiKey
{
    self = [super init];
    if (self) {
        self.apiKey = apiKey;
        return self;
    }
    return nil;
}


//Set the API Key for Google - preferred method is init, but just to keep it flexible
- (void)setApiKey:(NSString *)apiKey
{
    self.apiKey = apiKey;
}


//Give the option to return just the URL of the image for some developers who like to use AF, Caching, or SDWebImage
- (void)getImageURLWithLocation:(CLLocationCoordinate2D)location type:(NSString *)type name:(NSString *)name callback:(RMURLCallback)callback
{
    //Check for errors and return if there is something wrong with the parameters, this should be handled by the owner
    NSError *error = [self checkForErrorsWithLocation:location type:type name:name andCallback:callback];
    if (error != nil) {
        callback(error, nil);
        return;
    }
    
    //Create the url using the parameters and the api key
    NSString *googlePlaceUrlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%f&radius=50&type=%@&name=%@&key=%@", location.latitude, location.longitude, type, [self sanitizedName:name], self.apiKey];
    NSLog(@"place url string: %@", googlePlaceUrlString);
    
    //Creating a data callback to handle the returned data from Google
    RequestDataCallback dataCallback = ^(NSData *data) {
        //Get the first place in the array
        NSDictionary *place = [self placeFromResultsData:data];
        if (place != nil) {
            //If the place exists get the url from the first photo (likely to be most relevant) and return it in the callback
            NSString *urlString = [self getPhotoURL:[place objectForKey:@"photos"]];
            NSURL *url = [NSURL URLWithString:urlString];
            callback(nil, url);
        } else {
            //If there is no place then an error occurred trying to get the image
            NSError *imageError = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorNoCallback userInfo:[NSDictionary dictionaryWithObject:@"Error getting image data" forKey:@"Error"]];
            callback(imageError, nil);
        }
    };
    
    //Get the Results from Google
    [self getRequestWithEndpoint:googlePlaceUrlString body:nil andCallback:dataCallback];
}


//Optionally get the Image itself from Google instead of just the URL
- (void)getImageWithLocation:(CLLocationCoordinate2D)location type:(NSString *)type name:(NSString *)name callback:(RMPhotoCallback)callback
{
    //Check for errors and return if there is something wrong with the parameters
    NSError *error = [self checkForErrorsWithLocation:location type:type name:name andCallback:callback];
    if (error != nil) {
        callback(error, nil);
        return;
    }
    
    //Create the url
    NSString *googlePlaceUrlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%f&radius=50&type=%@&name=%@&key=%@", location.latitude, location.longitude, type, [self sanitizedName:name], self.apiKey];
    NSLog(@"place url string: %@", googlePlaceUrlString);
    
    RequestDataCallback dataCallback = ^(NSData *data) {
        [self processData:data withCallback:callback];
    };
    
    //Get the Data
    [self getRequestWithEndpoint:googlePlaceUrlString body:nil andCallback:dataCallback];
}


//Process the data results from Google to get and return an image
- (void)processData:(NSData *)data withCallback:(RMPhotoCallback)callback
{
    //Get the first place from the results and null check and handle appropriately
    NSDictionary *place = [self placeFromResultsData:data];
    if (place != nil) {
        //Get the photos array from the Place and null check and handle appropriately
        NSArray *photos = [place objectForKey:@"photos"];
        
        if (photos != nil && [photos count] == 0) {
            NSError *imageError = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorNoCallback userInfo:[NSDictionary dictionaryWithObject:@"Error getting image data" forKey:@"Error"]];
            callback(imageError, nil);
        }
        
        //Get the Photo data
        [self getGooglePhotos:photos andCallback:^(NSData *data) {
            //Null check the data and hanble
            if (data != nil) {
                //Create the image from the data and return in the passed callback
                UIImage *placeImage = [UIImage imageWithData:data];
                callback(nil, placeImage);
            } else {
                NSError *imageError = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorNoCallback userInfo:[NSDictionary dictionaryWithObject:@"Error getting image data" forKey:@"Error"]];
                callback(imageError, nil);
            }
        }];
        
        NSError *imageError = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorNoCallback userInfo:[NSDictionary dictionaryWithObject:@"Error getting image data" forKey:@"Error"]];
        callback(imageError, nil);
    } else {
        NSError *imageError = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorNoCallback userInfo:[NSDictionary dictionaryWithObject:@"Error getting image data" forKey:@"Error"]];
        callback(imageError, nil);
    }
}


#pragma mark - Helpers
//Helper to check for and return any errors associated with the parameters - using id for callback to handle both image and url callbacks
- (NSError *)checkForErrorsWithLocation:(CLLocationCoordinate2D)location type:(NSString *)type name:(NSString *)name andCallback:(id)callback
{
    NSError *error = nil;
    if (!CLLocationCoordinate2DIsValid(location)) {
        NSLog(@"RMGooglePlacesPhotosUtil: Error Location is Invalid");
        error = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorInvalidLocation userInfo:[NSDictionary dictionaryWithObject:@"Invalid Location" forKey:@"Error"]];
        return error;
    } else if (type == nil || [type length] == 0) {
        NSLog(@"RMGooglePlacesPhotosUtil: Error Type is Invalid");
        error = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorInvalidType userInfo:[NSDictionary dictionaryWithObject:@"Invalid or emptyType" forKey:@"Error"]];
        return error;
    } else if (name == nil || [name length] == 0) {
        NSLog(@"RMGooglePlacesPhotosUtil: Error Name is Invalid");
        error = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorInvalidName userInfo:[NSDictionary dictionaryWithObject:@"Invalid or empty Name" forKey:@"Error"]];
        return error;
    } else if (callback == nil) {
        NSLog(@"RMGooglePlacesPhotosUtil: Error No Callback");
        error = [NSError errorWithDomain:NSItemProviderErrorDomain code:RMPhotoErrorNoCallback userInfo:[NSDictionary dictionaryWithObject:@"No Callback - add a callback for the returned image" forKey:@"Error"]];
        return error;
    }
    return nil;
}


//Get the place from the data results and return nil if something is wrong with the data
- (NSDictionary *)placeFromResultsData:(NSData *)data
{
    if (data == nil) {
        return nil;
    }
    NSError *jsonError = nil;
    NSDictionary *gData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonError];
    
    if (jsonError != nil) {
        return nil;
    }
    
    NSArray *results = [gData objectForKey:@"results"];
    if (results.count != 0) {
        //Getting the closest reference to the Place
        NSDictionary *place = [results objectAtIndex:0];
        return place;
    } else {
        return nil;
    }
}


//Get the photo url - used in both the get google photos and get photo url
-(NSString *)getPhotoURL:(NSArray *)photos
{
    NSDictionary *photo = [photos firstObject];
    NSString *reference = [photo objectForKey:@"photo_reference"];
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?maxwidth=1400&photoreference=%@&key=AIzaSyAAc3iUQR2KTQg8_nnRCNs2DXkJen2siVE", reference];
    
    return urlString;
}


//Getting the photo url and data
- (void)getGooglePhotos:(NSArray *)photos andCallback:(RequestDataCallback)callback
{
    NSString *urlString = [self getPhotoURL:photos];
    NSLog(@"photo url: %@", urlString);
    [self getRequestWithEndpoint:urlString body:nil andCallback:^(NSData *data) {
        callback(data);
    }];
}


//Sanitizing the name so we can add it as a query item in the url
- (NSString *)sanitizedName:(NSString *)itemName
{
    itemName = [itemName stringByReplacingOccurrencesOfString:@"'" withString:@""];
    itemName = [itemName stringByReplacingOccurrencesOfString:@"&" withString:@""];
    
    return [itemName stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}


//Helper to send the request
-(void)getRequestWithEndpoint:(NSString *)endPoint body:(NSDictionary *)body andCallback:(RequestDataCallback)callback
{
    
    NSURL *url = [NSURL URLWithString:endPoint];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //up up
        callback(data);
    }];
    
    [dataTask resume];
}

@end

