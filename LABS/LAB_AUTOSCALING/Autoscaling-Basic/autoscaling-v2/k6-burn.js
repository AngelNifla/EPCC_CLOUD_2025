import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '3m', target: 20 },  // fase de calentamiento
    { duration: '5m', target: 60 },  // sostenido para disparar scale-out
    { duration: '3m', target: 0 },   // bajada para ver scale-in
  ],
};

const ALB = __ENV.ALB;

export default function () {
  http.get(`http://${ALB}/burn?n=800`); // <— menos “fuego” por request
  sleep(0.5);
}
