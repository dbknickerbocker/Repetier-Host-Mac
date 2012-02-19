/*
 Copyright 2011 repetier repetierdev@googlemail.com
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


#import "RHManualControl.h"
#import "PrinterConnection.h"

@implementation RHManualControl

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([NSBundle loadNibNamed:@"ManualControl" owner:self])
        {
            [view setFrame:[self bounds]];
            [self addSubview:view];
            [[NSNotificationCenter defaultCenter] addObserver:self                                             selector:@selector(connectionOpened:) name:@"RHConnectionOpen" object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self                                             selector:@selector(connectionClosed:) name:@"RHConnectionClosed" object:nil];
            [self updateConnectionStatus:NO];
            [self scrollPoint:NSMakePoint(0,0)];
            lastx = lasty = lastz = -1000;
            timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                     target:self selector:@selector(timerTick:)
                                                   userInfo:nil repeats:YES];
        }
    }
    
    return self;
}
-(BOOL)isFlipped {
    return YES;
}
- (void)timerTick:(NSTimer*)theTimer {
    if(connection->connected==NO) return;
    if (connection->analyzer->x != -lastx)
    {
        [xLabel setStringValue:[NSString stringWithFormat:@"X=%.2f",connection->analyzer->x]];
        if (connection->analyzer->hasXHome)
         [xLabel setTextColor:[NSColor blackColor]];
        else
          [xLabel setTextColor:[NSColor redColor]];
        lastx = connection->analyzer->x;
    }
    if (connection->analyzer->y != lasty)
    {
        [yLabel setStringValue:[NSString stringWithFormat:@"Y=%.2f",connection->analyzer->y]];
        if (connection->analyzer->hasYHome)
            [yLabel setTextColor:[NSColor blackColor]];
        else
            [yLabel setTextColor:[NSColor redColor]];
        lasty = connection->analyzer->y;
    }
    if (connection->analyzer->z != lastz)
    {
        [zLabel setStringValue:[NSString stringWithFormat:@"Z=%.2f",connection->analyzer->z]];
        if (connection->analyzer->hasZHome)
            [zLabel setTextColor:[NSColor blackColor]];
        else
            [zLabel setTextColor:[NSColor redColor]];
        lastz = connection->analyzer->z;
    }
}
-(void)updateConnectionStatus:(BOOL)c {
    [debugEchoButton setEnabled:c];
    [debugInfoButton setEnabled:c];
    [debugErrorButton setEnabled:c];
    [debugDryRunButton setEnabled:c];
    [powerButton setEnabled:c];
    [sendButton setEnabled:c];
    [xHomeButton setEnabled:c];
    [xMoveButtons setEnabled:c];
    [yHomeButton setEnabled:c];
    [yMoveButtons setEnabled:c];
    [zHomeButton setEnabled:c];
    [zMoveButtons setEnabled:c];
    [homeAllButton setEnabled:c];
    [goDumpAreaButton setEnabled:c];
    [stopMotorButton setEnabled:c];
    [fakeOkButton setEnabled:c];
    [extruderOnButton setEnabled:c];
    [extruderSetTempButton setEnabled:c];
    [extruderReverseButton setEnabled:c];
    [extruderExtrudeButton setEnabled:c];
    [heatedBedOnButton setEnabled:c];
    [heatedBedSetTempButton setEnabled:c];
    [fanOnButton setEnabled:c];
    [fanSpeedSlider setEnabled:c];
    [extruderLengthSlider setEnabled:c];
    [extruderSpeedSlider setEnabled:c];
    [gcodeText setEnabled:c];
    [extruderTempText setEnabled:c];
    [heatedBedTempText setEnabled:c];
    [extruderSpeedText setEnabled:c];
    [extrudeDistanceText setEnabled:c];
    [retractDistanceText setEnabled:c];
}
- (void)connectionOpened:(NSNotification *)notification {
    [self updateConnectionStatus:YES];
}
- (void)connectionClosed:(NSNotification *)notification {
    [self updateConnectionStatus:NO];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}
-(void)sendDebug {
    int v = 0;
    if ([debugEchoButton state]==1) v += 1;
    if ([debugInfoButton state]==1) v += 2;
    if ([debugErrorButton state]==1) v += 4;
    if ([debugDryRunButton state]==1) v += 8;
    [connection injectManualCommand:[NSString stringWithFormat:@"M111 S%d",v]];
}
- (IBAction)debugEchoAction:(NSButton *)sender {
    [self sendDebug];
}

- (IBAction)debugInfoAction:(NSButton *)sender {
    [self sendDebug];
}

- (IBAction)debugErrorsAction:(NSButton *)sender {
    [self sendDebug];
}

- (IBAction)debugDryRunAction:(NSButton *)sender {
    [self sendDebug];
}

- (IBAction)powerAction:(NSButton *)sender {
    if ([powerButton state]==1)
        [connection injectManualCommand:@"M80"];
    else
        [connection injectManualCommand:@"M81"];
}

- (IBAction)sendAction:(NSButton *)sender {
    [gcodeText sendCommand:gcodeText.stringValue];
}

- (IBAction)xHomeAction:(NSButton *)sender {
    [connection getInjectLock];
    [connection injectManualCommand:@"G28 X0"];
    [connection returnInjectLock ];
}

- (IBAction)yHomeAction:(NSButton *)sender {
    [connection getInjectLock];
    [connection injectManualCommand:@"G28 Y0"];
    [connection returnInjectLock ];
}

- (IBAction)zHomeAction:(NSButton *)sender {
    [connection getInjectLock];
    [connection injectManualCommand:@"G28 Z0"];
    [connection returnInjectLock ];
}
-(void) moveHead:(NSString*)axis distance:(double)amount {
    [connection getInjectLock];
    //BOOL wasrel = con.analyzer.relative;
    //if(!wasrel) 
    [connection injectManualCommand:@"G91"];
    if([axis compare:@"Z"]==NSOrderedSame)
        [connection injectManualCommand:[NSString stringWithFormat:@"G1 %@%1.1f F%1.0f",axis,amount,connection->config->travelZFeedrate]];
    else
        [connection injectManualCommand:[NSString stringWithFormat:@"G1 %@%1.1f F%1.0f",axis,amount,connection->config->travelFeedrate]];
    //if (!wasrel) 
    [connection injectManualCommand:@"G90"];
    [connection returnInjectLock ];
}
- (IBAction)xMoveAction:(NSSegmentedControl *)sender {
    switch ([sender selectedSegment]) {
        case 0:
            [self moveHead:@"X" distance:-100];
            break;
        case 1:
            [self moveHead:@"X" distance:-10];
            break;
        case 2:
            [self moveHead:@"X" distance:-1];
            break;
        case 3:
            [self moveHead:@"X" distance:-0.1];
            break;
        case 4:
            [self moveHead:@"X" distance:0.1];
            break;
        case 5:
            [self moveHead:@"X" distance:1];
            break;
        case 6:
            [self moveHead:@"X" distance:10];
            break;
        case 7:
            [self moveHead:@"X" distance:100];
            break;
    }
}

- (IBAction)yMoveAction:(NSSegmentedControl *)sender {
    switch ([sender selectedSegment]) {
        case 0:
            [self moveHead:@"Y" distance:-100];
            break;
        case 1:
            [self moveHead:@"Y" distance:-10];
            break;
        case 2:
            [self moveHead:@"Y" distance:-1];
            break;
        case 3:
            [self moveHead:@"Y" distance:-0.1];
            break;
        case 4:
            [self moveHead:@"Y" distance:0.1];
            break;
        case 5:
            [self moveHead:@"Y" distance:1];
            break;
        case 6:
            [self moveHead:@"Y" distance:10];
            break;
        case 7:
            [self moveHead:@"Y" distance:100];
            break;
    }
}

- (IBAction)zMoveAction:(NSSegmentedControl *)sender {
    switch ([sender selectedSegment]) {
        case 0:
            [self moveHead:@"Z" distance:-100];
            break;
        case 1:
            [self moveHead:@"Z" distance:-10];
            break;
        case 2:
            [self moveHead:@"Z" distance:-1];
            break;
        case 3:
            [self moveHead:@"Z" distance:-0.1];
            break;
        case 4:
            [self moveHead:@"Z" distance:0.1];
            break;
        case 5:
            [self moveHead:@"Z" distance:1];
            break;
        case 6:
            [self moveHead:@"Z" distance:10];
            break;
        case 7:
            [self moveHead:@"Z" distance:100];
            break;
    }
}

- (IBAction)homeAllAction:(NSButton *)sender {
    [connection getInjectLock];
    [connection injectManualCommand:@"G28 X0 Y0 Z0"];
    [connection returnInjectLock ];
}

- (IBAction)goDumpAreaAction:(NSButton *)sender {
    [connection doDispose];
}

- (IBAction)stopMotorAction:(NSButton *)sender {
    [connection injectManualCommand:@"M84" ];
}

- (IBAction)fakeOKAction:(NSButton *)sender {
    [connection analyzeResponse:@"ok"];
}

- (IBAction)heatOnAction:(NSButton *)sender {
    if (connection->connected == false) return;
    //if (!createCommands) return;
    [connection getInjectLock];
    if (sender.state)
    {
        [connection injectManualCommand:[NSString stringWithFormat:@"M104 S%d",(int)extruderTempText.intValue]];
    }
    else
    {
        [connection injectManualCommand:@"M104 S0"];
    }
    [connection returnInjectLock];
}

- (IBAction)extruderSetTempAction:(NSButton *)sender {
    [connection injectManualCommand:[NSString stringWithFormat:@"M104 S%d",(int)extruderTempText.intValue]];
}


- (IBAction)extruderExtrudeAction:(NSButton *)sender {
    [connection getInjectLock];
    BOOL wasrel = connection->analyzer->relative;
    if (!wasrel) [connection injectManualCommand:@"G91"];
    [connection injectManualCommand:[NSString stringWithFormat:@"G1 E%1.4f F%1f",[extrudeDistanceText doubleValue],[extruderSpeedText doubleValue]]];
    if (!wasrel) [connection injectManualCommand:@"G90"];
    [connection returnInjectLock ];
}

- (IBAction)heatedBedOnAction:(NSButton *)sender {
    if (connection->connected == false) return;
    //if (!createCommands) return;
    [connection getInjectLock];
    if (sender.state)
    {
        [connection injectManualCommand:[NSString stringWithFormat:@"M140 S%d",(int)heatedBedTempText.intValue]];
    }
    else
    {
        [connection injectManualCommand:@"M140 S0"];
    }
    [connection returnInjectLock];
}

- (IBAction)heatedBedSetTempAction:(NSButton *)sender {
    [connection injectManualCommand:[NSString stringWithFormat:@"M140 S%d",(int)heatedBedTempText.intValue]];
}

- (IBAction)fanOnAction:(NSButton *)sender {
    if (connection->connected == false) return;   
    //if (!createCommands) return;
    [connection getInjectLock];
    if (sender.state)
    {
        [connection injectManualCommand:[NSString stringWithFormat:@"M106 S%d",(int)fanSpeedSlider.intValue]];
    }
    else
    {
        [connection injectManualCommand:@"M107"];
    }
    [connection returnInjectLock];
}

- (IBAction)fanSpeedChangedAction:(NSSlider *)sender {
    [fanOnButton setState:1];    
    [self fanOnAction:fanOnButton];
}

- (IBAction)retractExtruderAction:(NSButton *)sender {
    [connection getInjectLock];
    BOOL wasrel = connection->analyzer->relative;
    if (!wasrel) [connection injectManualCommand:@"G91"];
    [connection injectManualCommand:[NSString stringWithFormat:@"G1 E-%1.4f F%1f",[retractDistanceText doubleValue],[extruderSpeedText doubleValue]]];
    if (!wasrel) [connection injectManualCommand:@"G90"];
    [connection returnInjectLock ];
}
@end