#import "OPEManagedOsmWay.h"
#import "OPEManagedOsmNode.h"
#import "OPEManagedOsmTag.h"
#import "OPEGeo.h"
#import "OPEGeoCentroid.h"


@interface OPEManagedOsmWay ()

// Private interface goes here.

@end


@implementation OPEManagedOsmWay

@synthesize points = _points;

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super initWithDictionary:dictionary]) {
        self.element = [[Way alloc] initWithDictionary:dictionary];
    }
    return self;
}

-(NSData *) uploadXMLforChangset:(int64_t)changesetNumber
{
    NSMutableString * xml = [NSMutableString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];
    [xml appendString:[NSString stringWithFormat: @"<osm version=\"0.6\" generator=\"OSMPOIEditor\">"]];
    [xml appendFormat:@"<way id=\"%lld\" version=\"%lld\" changeset=\"%lld\">",self.element.elementID,self.element.version, changesetNumber];
    
    for(Node * node in self.element.nodes)
    {
        [xml appendFormat:@"<nd ref=\"%lld\"/>",node.elementID];
    }
    
    [xml appendString:[self tagsXML]];
    
    [xml appendFormat: @"</way> @</osm>"];
    
    return [xml dataUsingEncoding:NSUTF8StringEncoding];
    
}

-(NSString *)osmType
{
    return kOPEOsmElementWay;
}
-(NSString *)idKeyPrefix
{
    return @"w";
}

-(NSArray *)points
{
    if (!_points) {
        NSMutableArray * mutablePointsArray = [NSMutableArray array];
        for (Node * node in self.element.nodes)
        {
            CLLocationCoordinate2D center = node.coordinate;
            CLLocation * location = [[CLLocation alloc]initWithLatitude:center.latitude longitude:center.longitude];
            [mutablePointsArray addObject:location];
        }
        _points = mutablePointsArray;
    }
    return _points;
    
}

@end
