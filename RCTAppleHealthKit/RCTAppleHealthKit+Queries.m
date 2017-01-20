//
//  RCTAppleHealthKit+Queries.m
//  RCTAppleHealthKit
//
//  Created by Greg Wilson on 2016-06-26.
//  Copyright © 2016 Greg Wilson. All rights reserved.
//

#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"

@implementation RCTAppleHealthKit (Queries)


- (void)fetchMostRecentQuantitySampleOfType:(HKQuantityType *)quantityType
                                  predicate:(NSPredicate *)predicate
                                 completion:(void (^)(HKQuantity *, NSDate *, NSDate *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc]
            initWithKey:HKSampleSortIdentifierEndDate
              ascending:NO
    ];

    HKSampleQuery *query = [[HKSampleQuery alloc]
            initWithSampleType:quantityType
                     predicate:predicate
                         limit:1
               sortDescriptors:@[timeSortDescriptor]
                resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {

                      if (!results) {
                          if (completion) {
                              completion(nil, nil, nil, error);
                          }
                          return;
                      }

                      if (completion) {
                          // If quantity isn't in the database, return nil in the completion block.
                          HKQuantitySample *quantitySample = results.firstObject;
                          HKQuantity *quantity = quantitySample.quantity;
                          NSDate *startDate = quantitySample.startDate;
                          NSDate *endDate = quantitySample.endDate;
                          completion(quantity, startDate, endDate, error);
                      }
                }
    ];
    [self.healthStore executeQuery:query];
}


- (void)fetchQuantitySamplesOfType:(HKQuantityType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];

    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKQuantitySample *sample in results) {
                    HKQuantity *quantity = sample.quantity;
                    double value = [quantity doubleValueForUnit:unit];

                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];

                    NSDictionary *elem = @{
                            @"value" : @(value),
                            @"startDate" : startDateString,
                            @"endDate" : endDateString,
                    };

                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}









- (void)fetchSleepCategorySamplesForPredicate:(NSPredicate *)predicate
                                   limit:(NSUInteger)lim
                                   completion:(void (^)(NSArray *, NSError *))completion {


    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:false];


    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKCategorySample *sample in results) {

                    // HKCategoryType *catType = sample.categoryType;
                    NSInteger val = sample.value;

                    // HKQuantity *quantity = sample.quantity;
                    // double value = [quantity doubleValueForUnit:unit];

                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];

                    NSString *valueString;

                    switch (val) {
                      case HKCategoryValueSleepAnalysisInBed:
                        valueString = @"INBED";
                      break;
                      case HKCategoryValueSleepAnalysisAsleep:
                        valueString = @"ASLEEP";
                      break;
                     default:
                        valueString = @"UNKNOWN";
                     break;
                  }

                    NSDictionary *elem = @{
                            @"value" : valueString,
                            @"startDate" : startDateString,
                            @"endDate" : endDateString,
                    };

                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    // HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
    //                                                        predicate:predicate
    //                                                            limit:lim
    //                                                  sortDescriptors:@[timeSortDescriptor]
    //                                                   resultsHandler:handlerBlock];

    HKCategoryType *categoryType =
    [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];

    // HKCategorySample *categorySample =
    // [HKCategorySample categorySampleWithType:categoryType
    //                                    value:value
    //                                startDate:startDate
    //                                  endDate:endDate];


   HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType
                                                          predicate:predicate
                                                              limit:lim
                                                    sortDescriptors:@[timeSortDescriptor]
                                                     resultsHandler:handlerBlock];


    [self.healthStore executeQuery:query];
}













- (void)fetchCorrelationSamplesOfType:(HKQuantityType *)quantityType
                                 unit:(HKUnit *)unit
                            predicate:(NSPredicate *)predicate
                            ascending:(BOOL)asc
                                limit:(NSUInteger)lim
                           completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];

    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKCorrelation *sample in results) {
                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];

                    NSDictionary *elem = @{
                      @"correlation" : sample,
                      @"startDate" : startDateString,
                      @"endDate" : endDateString,
                    };
                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

- (void)fetchSumOfSamplesOnDayForType:(HKQuantityType *)quantityType
                                 unit:(HKUnit *)unit
                                  day:(NSDate *)day
                           completion:(void (^)(double, NSDate *, NSDate *, NSError *))completionHandler {

    NSPredicate *predicate = [RCTAppleHealthKit predicateForSamplesOnDay:day];
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType
                                                          quantitySamplePredicate:predicate
                                                          options:HKStatisticsOptionCumulativeSum
                                                          completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                                                              HKQuantity *sum = [result sumQuantity];
                                                              NSDate *startDate = result.startDate;
                                                              NSDate *endDate = result.endDate;
                                                              
                                                              if (completionHandler) {
                                                                     double value = [sum doubleValueForUnit:unit];
                                                                     completionHandler(value,startDate, endDate, error);
                                                              }
                                                          }];

    [self.healthStore executeQuery:query];
}


- (void)fetchCumulativeSumStatisticsCollection:(HKQuantityType *)quantityType
                                          unit:(HKUnit *)unit
                                     startDate:(NSDate *)startDate
                                       endDate:(NSDate *)endDate
                                    completion:(void (^)(NSArray *, NSError *))completionHandler {

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.day = 1;

    NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                     fromDate:[NSDate date]];
    anchorComponents.hour = 0;
    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];

    // Create the query
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                                                           quantitySamplePredicate:nil
                                                                                           options:HKStatisticsOptionCumulativeSum
                                                                                        anchorDate:anchorDate
                                                                                intervalComponents:interval];

    // Set the results handler
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",error.localizedDescription);
        }

        NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
        [results enumerateStatisticsFromDate:startDate
                                      toDate:endDate
                                   withBlock:^(HKStatistics *result, BOOL *stop) {

                                       HKQuantity *quantity = result.sumQuantity;
                                       if (quantity) {
                                           NSDate *date = result.startDate;
                                           double value = [quantity doubleValueForUnit:[HKUnit countUnit]];
                                           NSLog(@"%@: %f", date, value);

                                           NSString *dateString = [RCTAppleHealthKit buildISO8601StringFromDate:date];
                                           NSArray *elem = @[dateString, @(value)];
                                           [data addObject:elem];
                                       }
                                   }];
        NSError *err;
        completionHandler(data, err);
    };

    [self.healthStore executeQuery:query];
}


- (void)fetchCumulativeSumStatisticsCollection:(HKQuantityType *)quantityType
                                          unit:(HKUnit *)unit
                                     startDate:(NSDate *)startDate
                                       endDate:(NSDate *)endDate
                                     ascending:(BOOL)asc
                                         limit:(NSUInteger)lim
                                    completion:(void (^)(NSArray *, NSError *))completionHandler {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:HKSampleSortIdentifierEndDate
                                            ascending:TRUE
                                            ];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    NSMutableArray *dataSources = [[NSMutableArray alloc] init];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]
                                                           predicate:predicate
                                                               limit:1000
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:^(HKSampleQuery *query, NSArray<HKQuantitySample*> *sources, NSError *error){
                                                    
                                                          for (HKQuantitySample* sample in sources) {
                                                              
                                                              HKSource* source = sample.sourceRevision.source;
                                                              if ([source.bundleIdentifier isEqualToString:@"com.apple.Health"]) {
                                                                  continue;
                                                              }
                                                              
                                                              HKDevice *device = sample.device;
                                                              NSLog(@"device : %@", device.name);
                                                              NSLog(@"device : %@", device.manufacturer);
                                                              NSLog(@"device : %@", device.model);
                                                              NSLog(@"device : %@", device.hardwareVersion);
                                                              NSLog(@"device : %@", device.firmwareVersion);
                                                              NSLog(@"device : %@", device.softwareVersion);
                                                              NSLog(@"device : %@", device.localIdentifier);
                                                              NSLog(@"device : %@", device.UDIDeviceIdentifier);
                                                              double value = [sample.quantity doubleValueForUnit:unit];
                                                              
                                                              NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                                                              NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];
                                                              NSMutableDictionary *elem = [NSMutableDictionary new];
                                                              if (device != NULL && device.name != NULL) {
                                                                  [elem setObject:device.name forKey:@"name"];
                                                              }
                                                              if (device != NULL && device.manufacturer != NULL) {
                                                                  [elem setObject:device.manufacturer forKey:@"manufacturer"];
                                                              }
                                                              if (device != NULL && device.model != NULL) {
                                                                  [elem setObject:device.model forKey:@"model"];
                                                              }
                                                              if (device != NULL && device.hardwareVersion != NULL) {
                                                                  [elem setObject:device.hardwareVersion forKey:@"hardwareVersion"];
                                                              }
                                                              if (device != NULL && device.firmwareVersion != NULL) {
                                                                  [elem setObject:device.firmwareVersion forKey:@"firmwareVersion"];
                                                              }
                                                              if (device != NULL && device.softwareVersion != NULL) {
                                                                  [elem setObject:device.softwareVersion forKey:@"softwareVersion"];
                                                              }
                                                              if (device != NULL && device.localIdentifier != NULL) {
                                                                  [elem setObject:device.localIdentifier forKey:@"localIdentifier"];
                                                              }
                                                              if (device != NULL && device.UDIDeviceIdentifier != NULL) {
                                                                  [elem setObject:device.UDIDeviceIdentifier forKey:@"UDIDeviceIdentifier"];
                                                              }
                                                              if (device != NULL) {
                                                                  [elem setObject:@(value) forKey:@"value"];
                                                              }
                                                              if (device != NULL && startDateString != NULL) {
                                                                  [elem setObject:startDateString forKey:@"startDate"];
                                                              }
                                                              if (device != NULL && endDate != NULL) {
                                                                  [elem setObject:endDateString forKey:@"endDate"];
                                                              }
                                                              
                                                              [dataSources addObject:elem];
                                                            
                                                          }
                                                          completionHandler(dataSources, nil);
                                                      }];
    
    
    [self.healthStore executeQuery:query];
     
    /*
    NSMutableArray *dataSources = [[NSMutableArray alloc] init];
    HKQuantityType *stepsCount = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKSourceQuery *sourceQuery = [[HKSourceQuery alloc] initWithSampleType:stepsCount
                                                           samplePredicate:nil
                                                         completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error)
                                  {
                                      NSCalendar *calendar = [NSCalendar currentCalendar];
                                      NSDateComponents *interval = [[NSDateComponents alloc] init];
                                      interval.day = 1;
                                      
                                      NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                                       fromDate:[NSDate date]];
                                      anchorComponents.hour = 0;
                                      NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];

                                      __block volatile int index = 0;
                                      for (HKSource *source in sources) {
                                          if ([source.bundleIdentifier isEqualToString:@"com.apple.Health"]) {
                                              index++;
                                              continue;
                                          }
                                          NSPredicate *predicate = [HKQuery predicateForObjectsFromSource:source];
                                          
                                          HKStatisticsCollectionQuery *sourceQuery = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                                                                                                  quantitySamplePredicate:predicate
                                                                                                                                  options:HKStatisticsOptionCumulativeSum
                                                                                                                               anchorDate:anchorDate
                                                                                                                       intervalComponents:interval];
                                          sourceQuery.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
                                              if (error) {
                                                  NSLog(@"*** An error occurred while calculating the statistics: %@ ***", error.localizedDescription);
                                              }
                                              
                                              NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
                                              for (HKSource *source in results.sources) {
                                                  NSLog(@"results source %@",source);
                                              }
                                              [results enumerateStatisticsFromDate:startDate
                                                                            toDate:endDate
                                                                         withBlock:^(HKStatistics *result, BOOL *stop) {
                                                                             
                                                                             HKQuantity *quantity = result.sumQuantity;
                                                                             
                                                                             if (quantity) {
                                                                                 NSDate *startDate = result.startDate;
                                                                                 NSDate *endDate = result.endDate;
                                                                                 double value = [quantity doubleValueForUnit:unit];
                                                                                 
                                                                                 NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:startDate];
                                                                                 NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:endDate];
                                                                                 NSDictionary *elem = @{
                                                                                                        @"value" : @(value),
                                                                                                        @"startDate" : startDateString,
                                                                                                        @"endDate" : endDateString,
                                                                                                        };
                                                                                 [data addObject:elem];
                                                                             }
                                                                         }];
                                              // is ascending by default
                                              if(asc == false) {
                                                  [RCTAppleHealthKit reverseNSMutableArray:data];
                                              }
                                              NSMutableArray *sourcesData = [NSMutableArray new];
                                              NSMutableDictionary *sourceDic = [NSMutableDictionary new];
                                              [sourceDic setObject:source.name forKey:@"name"];
                                              [sourceDic setObject:source.bundleIdentifier forKey:@"identifier"];
                                              
                                              if(lim > 0) {
                                                  NSArray* slicedArray = [data subarrayWithRange:NSMakeRange(0, lim)];
                                                  [sourceDic setObject:slicedArray forKey:@"data"];
                                                  [sourcesData addObject:sourceDic];
                                              } else {
                                                  [sourceDic setObject:data forKey:@"data"];
                                                  [sourcesData addObject:sourceDic];
                                              }
                                              [dataSources addObject:sourcesData];
                                              index++;
                                              if ([sources count] == index) {
                                                  completionHandler(dataSources, nil);
                                              }
                                          };
                                          
                                          [self.healthStore executeQuery:sourceQuery];
                                      }
                                  }];
    [self.healthStore executeQuery:sourceQuery];
     */
}

@end
