import * as React from 'react';

// Delete me
interface ThingProps {
  yesText?: string;
  noText?: string;
  Content?: string;
  criteria: string;
}

export const Thing: React.FC<ThingProps> = ({ yesText, noText, Content, criteria }): JSX.Element => {
  return   <div>
  <div style={{ "padding": "10px"}}>
      <h3>{criteria}</h3>
  </div>
  <div style={{"width":"100%","height":"150px","backgroundColor":"#f0f0f0"}}>
      {Content}
  </div>
  <div className="post-buttons">
      <button style={{"border":"none","backgroundColor":"transparent","cursor":"pointer","padding":"5px 10px","borderRadius":"5px","transition":"background-color 0.3s"}}>{noText}</button>
      <button style={{"border":"none",
      "backgroundColor":"transparent",
      "cursor":"pointer",
      "padding":"5px 10px",
      "borderRadius":"5px",
      "transition":"background-color 0.3s"
      }}>{yesText}</button>
  </div>
  <div className="post-content">
      {/* Add post content here (e.g., captions, comments) */}
  </div>
</div>
};
