//
//  GameScene.m
//  Balling
//
//  Created by Pietro Ribeiro Pepe on 3/9/15.
//  Copyright (c) 2015 Pietro Ribeiro Pepe. All rights reserved.
//

#import "GameScene.h"
#import <AVFoundation/AVFoundation.h>

@implementation GameScene

CGFloat speed=100.0, lastTime=0;
NSMutableArray *elements, *placers;
CFTimeInterval elapsedTime=0;
CGFloat distanceTraveled=0;
CGFloat spacing;
CGFloat distance;
SKSpriteNode *ball;
SKAction *movement;
CGFloat floorHeight = 20;

NSMutableArray *audioPlayerArray;

CFTimeInterval timePaseed;

NSInteger sign;

NSMutableArray *sinShots;

//Not using yet
static const uint32_t floorCategory = 0x1 << 1;
static const uint32_t ballCategory = 0x1 << 2;
static const uint32_t shotCategory = 0x1 << 3;
static const uint32_t spikeCategory = 0x1 << 4;


bool moving=false;
bool isJumping=false;

-(void)didMoveToView:(SKView *)view {
    lastTime=0;
    spacing=120;
    timePaseed=0;
    SKPhysicsBody* borderBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody = borderBody;
    self.physicsBody.friction=0.0f;
    self.physicsWorld.contactDelegate = self;
    
    distance = 2*spacing+self.frame.size.height;
    movement = [SKAction moveByX:0 y:distance duration:distance/speed];
    movement = [SKAction sequence:@[movement,[SKAction removeFromParent]]];
    /* Setup your scene here */
    SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    myLabel.text = @"Hello, World!";
    myLabel.fontSize = 65;
    myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                   CGRectGetMidY(self.frame));
    
    //[self addChild:myLabel];
    elements = [NSMutableArray array];
    sinShots = [NSMutableArray array];
    placers = [NSMutableArray array];
    audioPlayerArray = [NSMutableArray array];
    ball = [SKSpriteNode spriteNodeWithImageNamed:@"ball"];
    [ball setSize:CGSizeMake(0.1*self.frame.size.width,0.1*self.frame.size.width)];
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ball.size.width*0.5 center:ball.position];
    ball.physicsBody.restitution=0.0f;
    ball.physicsBody.allowsRotation=YES;
    ball.position=CGPointMake(self.frame.size.width*0.2, self.frame.size.height);
    ball.physicsBody.contactTestBitMask=floorCategory | shotCategory | spikeCategory;
    ball.physicsBody.categoryBitMask=ballCategory;
    ball.physicsBody.linearDamping = 0;
    [self addChild:ball];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        NSLog(@"%f %f", location.x, location.y);
        if(location.y<self.frame.size.height*0.5)
            [self movementTouch:location];
        else
            [self jump];
    }
}

-(void)movementTouch:(CGPoint)location{
    moving=true;
    sign = (location.x>self.frame.size.width*0.5)?1:-1;
    
}

-(void)jump{
    if(!isJumping){
        isJumping=true;
        [ball.physicsBody applyImpulse:CGVectorMake(0, 19)];
        //ball.physicsBody.velocity = CGVectorMake(ball.physicsBody.velocity.dx, sqrtf(spacing*20));
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        if(location.y<self.frame.size.height*0.5 && moving)
            [self stopMovement];
    }
}


-(void)stopMovement{
    moving=false;
    ball.physicsBody.velocity=CGVectorMake(0, ball.physicsBody.velocity.dy);
    //Not sure if we are going to act on angularVelocity
    ball.physicsBody.angularVelocity=0.0f;
}

-(void)stopJump{
    if(isJumping){
        isJumping=false;
        ball.physicsBody.velocity=CGVectorMake(ball.physicsBody.velocity.dx, 0);
    }
}

-(void)didBeginContact:(SKPhysicsContact *)contact{
    SKSpriteNode *floor = (SKSpriteNode*)contact.bodyA.node;
    SKSpriteNode *ball = (SKSpriteNode*)contact.bodyB.node;
    if(floor.physicsBody.categoryBitMask == floorCategory){
        if(ball.position.y>floor.position.y){
            [self stopJump];
            NSLog(@"contact");
        }
    }
    else if (floor.physicsBody.categoryBitMask == shotCategory || floor.physicsBody.categoryBitMask == spikeCategory){
        [self die];
    }
}

-(void)didEndContact:(SKPhysicsContact *)contact{
    SKSpriteNode *floor = (SKSpriteNode*)contact.bodyA.node;
    //SKSpriteNode *ball = (SKSpriteNode*)contact.bodyB.node;
    if(floor.physicsBody.categoryBitMask == floorCategory)
        isJumping=true;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    distanceTraveled += speed*(currentTime-lastTime);
    //When we reach the space beetween floors
    if(distanceTraveled>=spacing){
        distanceTraveled=0;
        [self createNewFloor];
        if(placers.count>8){
            //[elements[0] removeFromParent];
            //[elements[1] removeFromParent];
            [placers[0] removeFromParent];
            [placers removeObjectAtIndex:0];
            [elements removeObjectAtIndex:0];
            [elements removeObjectAtIndex:0];
            [self prepareFire];
        }
    }
    timePaseed += currentTime-lastTime;
    lastTime=currentTime;
    if(ball.position.y>self.frame.size.height){
        [self die];
    }
    
    [self processGuys:currentTime];
    
}

-(void)prepareFire{
    
    if((float)rand()/RAND_MAX > 0.5)return;
    
    SKSpriteNode *mark = [SKSpriteNode spriteNodeWithImageNamed:@"attention"];
    [mark setSize:ball.size];
    mark.position = CGPointMake(0,mark.size.height*0.5 + ball.size.height*0.5);
    [self playSound:@"AlertSound" ofType:@"mp3"];
    [ball addChild:mark];
    [mark runAction:[SKAction sequence:@[[SKAction waitForDuration:0.8f],[SKAction runBlock:^{
        [mark removeFromParent];
        [self spawnFire];
    }]]]];
}

-(void)spawnFire{
    
    SKSpriteNode *placer = [self getBallActualPlacer];
    if(placer==nil)return;
    
    SKSpriteNode *fire = [SKSpriteNode spriteNodeWithColor:[UIColor yellowColor] size:ball.size];
    fire.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ball.size];
    fire.physicsBody.collisionBitMask = 0;
    fire.physicsBody.affectedByGravity=false;
    fire.physicsBody.categoryBitMask=shotCategory;
    
    
    CGFloat height, posX;
    NSInteger sign;
    CGFloat random = (float)rand()/RAND_MAX;
    if(random > 0.5){
        height = floorHeight*0.5 + (placer.size.height - floorHeight)*0.75;
        random -= 0.5;
    }
    else{
        height = floorHeight*0.5 + (placer.size.height - floorHeight)*0.25;
    }
    
    /* If we want to randomize the side of the fire
    if(random > 0.25){
        posX = 0;
        sign = 1;
    }
    else{
        posX = placer.size.width;
        sign=-1;
    }
     */
    //not randomized
    if(ball.position.x>placer.size.width*0.5){
        posX=0;
        sign=1;
    }
    else{
        posX=placer.size.width;
        sign=-1;
    }
    
    fire.physicsBody.velocity=CGVectorMake(sign*200, 0);
    fire.position = CGPointMake(posX, height);
    
    /* Bad delay when using it here (let`s try it outside of function)
    SKSpriteNode *mark = [SKSpriteNode spriteNodeWithImageNamed:@"attention"];
    [mark setSize:ball.size];
    mark.position = fire.position;
    [placer addChild:mark];
    [mark runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5f],[SKAction runBlock:^{
        [mark removeFromParent];
        [placer addChild:fire];
    }]]]];
     */
    
    [placer addChild:fire];
}

-(SKSpriteNode*)getBallActualPlacer{
    for(SKSpriteNode *placer in placers)
        if(placer.position.y<ball.position.y)
            return placer;
    return nil;
}

-(void)die{
    [ball runAction:[SKAction moveTo:CGPointMake(self.frame.size.width*0.5, self.frame.size.height*0.5) duration:0.0f]];
    ball.physicsBody.velocity = CGVectorMake(0, 0);
}

-(void)processGuys:(CFTimeInterval)ct{
    NSMutableArray *toRemove = [NSMutableArray array];
    for(SKSpriteNode *shot in sinShots){
        CGFloat height = 0.6*spacing*cosf(4*M_PI*shot.position.x/self.frame.size.width);
        shot.physicsBody.velocity = CGVectorMake(shot.physicsBody.velocity.dx, height);
        if(shot.position.x>self.frame.size.width){
            [toRemove addObject:shot];
        }
    }
    for(SKSpriteNode *shot in toRemove){
        [sinShots removeObject:shot];
    }
}

-(void)didSimulatePhysics{
    if(!moving){
        ball.physicsBody.velocity=CGVectorMake(0,ball.physicsBody.velocity.dy);
    }
    else{
        ball.physicsBody.velocity=CGVectorMake(200*sign, ball.physicsBody.velocity.dy);
    }
}

-(void)createNewFloor{
    CGFloat holeSize = 1.5*ball.size.width;
    CGFloat placeX = holeSize*0.5 + ((float)rand()/RAND_MAX)*(self.frame.size.width-holeSize);
    CGFloat posY = -spacing;
    if(elements.count){
        posY += ((SKSpriteNode*)elements.lastObject).position.y;
    }
    CGSize size = CGSizeMake(self.frame.size.width,floorHeight);
    SKSpriteNode *placer = [SKSpriteNode node];
    [placer setSize:CGSizeMake(self.frame.size.width, spacing)];
    placer.anchorPoint = CGPointMake(0, 0);
    placer.position = CGPointMake(0, posY);
    SKSpriteNode *floor = [SKSpriteNode spriteNodeWithColor:[UIColor redColor] size:CGSizeMake(placeX-0.75*ball.size.width,size.height)];
    floor.position = CGPointMake(floor.size.width*0.5, 0);
    floor.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:floor.size];
    floor.physicsBody.affectedByGravity=false;
    floor.physicsBody.dynamic=false;
    floor.physicsBody.categoryBitMask=floorCategory;
    
    SKSpriteNode *floor2 = [SKSpriteNode spriteNodeWithColor:[UIColor redColor] size:CGSizeMake(self.frame.size.width-(placeX+0.75*ball.size.width),size.height)];
    floor2.position = CGPointMake(self.frame.size.width-floor2.size.width*0.5, 0);
    floor2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:floor2.size];
    floor2.physicsBody.affectedByGravity=false;
    floor2.physicsBody.dynamic=false;
    floor2.physicsBody.categoryBitMask=floorCategory;
    
    if(elements.count>2){
        
        //Here randomized stuff of the map (enemies, obstacles) will be generated
        [self generateShotAtPlacer:placer withSize:size];
        [self generateSpikeAtPlacer:placer withSize:size withFirstFloor:floor holeSize:holeSize];
    }
    
    [placer addChild:floor];
    [placer addChild:floor2];
    [self addChild:placer];
    [placer runAction:movement];
    [elements addObject:floor];
    [elements addObject:floor2];
    [placers addObject:placer];
}

-(void)generateShotAtPlacer:(SKSpriteNode*)placer withSize:(CGSize)size{
    CGFloat random = (float)rand()/RAND_MAX;
    if(random>0.5){
        NSInteger sign, posX;
        random-=0.5;
        if(random>0.25){
            posX = 0;
            sign = 1;
        }
        else{
            posX = placer.size.width;
            sign = -1;
        }
        SKSpriteNode *shot  = [SKSpriteNode spriteNodeWithColor:[UIColor blueColor] size:CGSizeMake(size.height, size.height)];
        shot.position = CGPointMake(posX, placer.size.height*0.5);
        shot.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:shot.size];
        shot.physicsBody.collisionBitMask = 0;
        shot.physicsBody.affectedByGravity=false;
        shot.physicsBody.categoryBitMask=shotCategory;
        //shot.physicsBody.velocity = CGVectorMake(100, distance/5) for old anchorPoint
        shot.physicsBody.velocity = CGVectorMake(sign*(80 + ((float)rand()/RAND_MAX)*30), 0);
        //[self addChild:shot];
        [placer addChild:shot];
        [sinShots addObject:shot];
    }
}

-(void)generateSpikeAtPlacer:(SKSpriteNode*)placer withSize:(CGSize)size withFirstFloor:(SKSpriteNode*)floor holeSize:(CGFloat)holeSize{
    
    if(((float)rand()/RAND_MAX)>0.0){
        
        size = CGSizeMake(size.height,size.height);
        
        NSInteger quant = elements.count;
        SKSpriteNode *f1 = elements[quant-2];
        CGFloat lastHole = f1.position.x + f1.size.width*0.5 + holeSize*0.5;
        CGFloat actualHole = floor.position.x + floor.size.width*0.5 + holeSize*0.5;
        CGFloat spikeField;
        if(actualHole<lastHole){
            actualHole += holeSize*0.5;
            lastHole -= holeSize*0.5;
            if(!(actualHole+size.width<lastHole)){
                return;
            }
            spikeField = lastHole - actualHole;
        }
        else{
            actualHole -= holeSize;
            lastHole += holeSize;
            if(!(actualHole>=lastHole+size.width)){
                return;
            }
            spikeField = actualHole - lastHole;
            actualHole = lastHole;
        }
        
        CGFloat position = actualHole + size.width*0.5 + ((float)rand()/RAND_MAX)*(spikeField-size.width);
        
        SKSpriteNode *spike = [SKSpriteNode spriteNodeWithImageNamed:@"spike-up"];
        [spike setSize:size];
        spike.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(size.width*0.8, size.height)];
        spike.position = CGPointMake(position, size.height);
        //physicsBody
        spike.physicsBody.affectedByGravity = false;
        spike.physicsBody.collisionBitMask = 0;
        spike.physicsBody.categoryBitMask = spikeCategory;
        [placer addChild:spike];
    }
}

-(void)playSound:(NSString*)filename ofType:(NSString*)type{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *filePath = [mainBundle pathForResource:filename ofType:type];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    [self clearAudio:audioPlayerArray];
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithData:fileData error:&error];
    [audioPlayer setVolume:1.0f];
    [audioPlayer prepareToPlay];
    [audioPlayer play];
    [audioPlayerArray addObject:audioPlayer];
}

-(void)clearAudio:(NSMutableArray*)array{
    NSInteger i, size=array.count;
    for(i=0;i<size;i++){
        AVAudioPlayer *ap = [array objectAtIndex:i];
        if(!ap.playing){
            [array removeObjectAtIndex:i--];
            size--;
        }
    }
}

@end
