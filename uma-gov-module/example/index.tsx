import 'react-app-polyfill/ie11';
import * as React from 'react';
import * as ReactDOM from 'react-dom';
import {Thing} from './../src/index';
import { Tabs, Tab } from './tabs';

const App = () => {
  return (
    <div style={{"border":"1px solid #dbdbdb","borderRadius":"10px","width":"300px","margin":"20px auto","backgroundColor":"white"}}>
      <div>
      <Tabs>
      <Tab label="Fact or Opinion">
        <Thing criteria='Criteria: All Fact' Content={"The Earth orbits the Sun."} yesText={"Fact"} noText={"Opinion"} />
        <Thing criteria='Criteria: 3/5 Facts and 2/5 Opinion' Content={"Coffee is Derived from Coffee Beans, Coffee is One of the Most Popular Beverages Worldwide, Caffeine is a Major Component of Coffee, Coffee Tastes Best When Freshly Brewed,Adding Sugar Ruins the True Flavor of Coffee"} yesText={"According to Criteria"} noText={"Not According"} />

      </Tab>

      <Tab label="Funny or Not">
        <Thing criteria='Criteria: Chuckle Laughter' Content={"Why don't scientists trust atoms? Because they make up everything!"} yesText={"Funny"} noText={"Not Funny"} />
        <Thing criteria='Criteria: ROFL' Content={"Why did the scarecrow win an award? Because he was outstanding in his field!"} yesText={"Funny"} noText={"Not Funny"} />
        <Thing criteria='Criteria: Smile' Content={"What do you call fake spaghetti? An impasta!"} yesText={"Funny"} noText={"Not Funny"} />

      </Tab>
        
      <Tab label="Deepfake or Real">
          Content for Tab 3
      </Tab>
      </Tabs>
    </div>
      
    </div>
  );
};

ReactDOM.render(<App />, document.getElementById('root'));
