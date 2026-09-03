import type { NuruRequest, NuruResponse } from '../types';

const responses: Record<string, NuruResponse> = {
  'Explain this more simply': {
    title: 'A simpler way to see it',
    body: 'Think of an equation like a balanced scale. Your goal is to leave x alone on one side. Whatever you do to one side, you must also do to the other.',
    followUp: 'Try the next step by subtracting 6 from both sides.',
  },
  'Give me another example': {
    title: 'Another example',
    body: 'For 4x + 8 = 24, first subtract 8 from both sides. That leaves 4x = 16. Then divide both sides by 4, so x = 4.',
    followUp: 'Notice how each step keeps both sides balanced.',
    example: '4x + 8 = 24',
  },
  'Why was my answer wrong?': {
    title: 'Let’s look at that step',
    body: 'You subtracted 6 correctly, but then divided 12 by 2 incorrectly. The final step should give x = 6.',
    followUp: 'A useful check is to substitute 6 back into the original equation.',
  },
};

export function getNuruResponse(request: NuruRequest): NuruResponse {
  return responses[request.question] ?? {
    title: 'A helpful next step',
    body: `Let’s connect this to ${request.context.lesson}. Start by identifying what you already know, then make one small change at a time.`,
    followUp: 'Try explaining the first step in your own words.',
  };
}
